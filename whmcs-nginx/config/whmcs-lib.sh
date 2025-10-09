set -eu
# enable pipefail where supported (BusyBox ash supports it)
(set -o pipefail 2>/dev/null) && set -o pipefail

# Defaults (override via env)
: "${WHMCS_WEB_ROOT:=/var/www/html}"
: "${WHMCS_STORAGE_DIR:=/var/www/whmcs_storage}"
: "${WHMCS_CHANNEL:=stable}"
: "${WHMCS_URL:=}"
: "${WHMCS_SHA256:=}"
: "${WHMCS_WRITE_UID:=33}"
: "${WHMCS_WRITE_GID:=33}"

log()  { echo "[whmcs-init] $*"; }
warn() { echo "[whmcs-init][WARN] $*" >&2; }
die()  { echo "[whmcs-init][ERROR] $*" >&2; exit 1; }

##
# Check if directory is empty, ignore (.gitignore)
##
is_empty_dir() {
  [ -d "$1" ] || return 2
  [ -z "$(find "$1" -mindepth 1 -maxdepth 1 ! -name '.gitignore' -print 2>/dev/null | head -n 1)" ]
}

##
# Replace or append a config option in .php config
# Usage: sed_set_or_append_php_var <file> <varname> <value>
##
sed_set_or_append_php_var() {
  f="$1"; v="$2"; val="$3"
  esc_val=$(printf "%s" "$val" | sed 's/[&/\]/\\&/g')
  if grep -q "^[[:space:]]*\\\$$v[[:space:]]*=" "$f"; then
    sed -i "s#^[[:space:]]*\\\$$v[[:space:]]*=.*#\$$v = '$esc_val';#" "$f"
  else
    printf "\n\$%s = '%s';\n" "$v" "$val" >> "$f"
  fi
}

##
# Create directories for whmcs_storage
##
ensure_tree_if_empty() {
  root="$1"; shift
  mkdir -p "$root"
  if is_empty_dir "$root"; then
    # build abs paths and create with exact perms
    abs=""
    for rel in "$@"; do abs="$abs $root/$rel"; done
    # shellcheck disable=SC2086
    install -d -m 0755 $abs
    chown -R "$WHMCS_WRITE_UID:$WHMCS_WRITE_GID" "$root"
    log "Initialized storage tree at $root"
  else
    log "$root has content; skipping storage init."
  fi
}

##
# Download WHMCS files via official API
##
fetch_whmcs_into() {
  dest="$1"
  tmp="$(mktemp -d)"; dir="$tmp/unzip"; mkdir -p "$dir"

  # Resolve download URL + checksum
  if [ -z "$WHMCS_URL" ]; then
    log "Querying WHMCS Distributions API (type=${WHMCS_CHANNEL})…"
    json="$(curl -fsSL "https://api1.whmcs.com/download/latest?type=${WHMCS_CHANNEL}")" || die "API request failed"
    url="$(echo "$json" | jq -r '.url')" || die "parse url failed"
    sha="$(echo "$json" | jq -r '.sha256Checksum' || true)"
  else
    url="$WHMCS_URL"; sha="$WHMCS_SHA256"
  fi
  [ -n "$url" ] && [ "$url" != "null" ] || die "No WHMCS download URL"

  # Download + verify
  log "Downloading WHMCS…"
  curl -fSL "$url" -o "$tmp/whmcs.zip" || die "Download failed"
  if [ -n "${sha:-}" ] && [ "$sha" != "null" ]; then
    echo "${sha}  $tmp/whmcs.zip" | sha256sum -c - || die "Checksum verification failed"
  else
    warn "No sha256Checksum provided; skipping verification."
  fi

  # Unzip to temp; some zips nest under top-level 'whmcs/'
  unzip -q "$tmp/whmcs.zip" -d "$dir" || die "Unzip failed"
  [ -d "$dir/whmcs" ] && src="$dir/whmcs" || src="$dir"

  # Ensure dest exists & owned by target uid/gid
  install -d -o "$WHMCS_WRITE_UID" -g "$WHMCS_WRITE_GID" -m 0755 "$dest"

  # Extract AS the target uid/gid (no chown -R needed)
  command -v su-exec >/dev/null 2>&1 || die "su-exec not found in PATH"
  (cd "$src" && tar -cf - .) | su-exec "$WHMCS_WRITE_UID:$WHMCS_WRITE_GID" tar -C "$dest" -xf - || die "Copy failed"

  rm -rf "$tmp"
  log "WHMCS installed to $dest (owned by $WHMCS_WRITE_UID:$WHMCS_WRITE_GID)"
}


####
## Functions below are executed manually by user post WHMCS installation
## due to WHMCS having to generate configuration.php after initial installation
####


##
# Move crons folder to whmcs_storage
# Update cron config and main whmcs config to reflect the new crons location
##
move_crons_to_storage() {
  src="$WHMCS_WEB_ROOT/crons"
  dst="$WHMCS_STORAGE_DIR/crons"

  [ -d "$src" ] || { log "No crons/ in web root; skipping move."; return 0; }

  mkdir -p "$dst"
  if ! is_empty_dir "$dst"; then
    log "$dst already has content; leaving crons/ as-is."
    return 0
  fi

  log "Moving crons/ to $dst …"
  cp -a "$src"/. "$dst"/ && rm -rf "$src"
  chown -R "$WHMCS_WRITE_UID:$WHMCS_WRITE_GID" "$dst"

  # Ensure crons/config.php exists (WHMCS may ship config.php.new)
  cron_cfg_new="$dst/config.php.new"
  cron_cfg="$dst/config.php"
  [ -f "$cron_cfg_new" ] && [ ! -f "$cron_cfg" ] && mv "$cron_cfg_new" "$cron_cfg"

  # Set $whmcspath inside crons/config.php (append if missing, replace if present)
  if [ -f "$cron_cfg" ]; then
    root_path="${WHMCS_WEB_ROOT%/}/"
    sed_set_or_append_php_var "$cron_cfg" "whmcspath" "$root_path"
  else
    warn "$cron_cfg not found; add \$whmcspath later."
  fi

  # Set $crons_dir in main configuration.php (append/replace)
  main_cfg="$WHMCS_WEB_ROOT/configuration.php"
  crons_path="${dst%/}/"
  if [ -f "$main_cfg" ]; then
    sed_set_or_append_php_var "$main_cfg" "crons_dir" "$crons_path"
  else
    warn "$main_cfg not found; complete the initial WHMCS installation first."
  fi

  log "crons/ moved and configs updated (per WHMCS guidance)."
}

##
# Set templates_c location to whmcs_storage
# This function simply appends config value with new path to templates_c 
##
set_templates_location() {
  main_cfg="$WHMCS_WEB_ROOT/configuration.php"
  [ -f "$main_cfg" ] || die "configuration.php not found; complete the initial WHMCS installation first."

  storage_tc="${WHMCS_STORAGE_DIR%/}/templates_c"

  # Ensure the target dir exists & is writable by PHP user
  install -d -o "$WHMCS_WRITE_UID" -g "$WHMCS_WRITE_GID" -m 0755 "$storage_tc" || true

  # Set/replace the config value
  sed_set_or_append_php_var "$main_cfg" "templates_compiledir" "${storage_tc%/}/"

  # Keep ownership sane (harmless if already correct)
  chown "$WHMCS_WRITE_UID:$WHMCS_WRITE_GID" "$main_cfg" || true

  log "Set \$templates_compiledir to ${storage_tc%/}/"
}