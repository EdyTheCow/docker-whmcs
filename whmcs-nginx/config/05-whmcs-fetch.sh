#!/bin/sh
set -eu

# -------------------- defaults (override via Docker env) --------------------
: "${WHMCS_WEB_ROOT:=/var/www/html}"
: "${WHMCS_STORAGE_DIR:=/var/www/whmcs_storage}"
: "${WHMCS_CHANNEL:=stable}"          # or beta|rc|preprod|any
: "${WHMCS_URL:=}"                    # if set, overrides channel
: "${WHMCS_SHA256:=}"                 # optional explicit checksum
: "${WHMCS_WRITE_UID:=33}"            # Debian www-data uid
: "${WHMCS_WRITE_GID:=33}"            # Debian www-data gid

log() { echo "[whmcs-init] $*"; }
warn() { echo "[whmcs-init][WARN] $*" >&2; }
die() { echo "[whmcs-init][ERROR] $*" >&2; exit 1; }

# Treat directory as empty if nothing (except '.gitignore')
is_empty_dir() {
  [ -z "$(find "$1" -mindepth 1 -maxdepth 1 -not -name '.gitignore' -print -quit 2>/dev/null)" ]
}

# Create a tree of subpaths only when the root is empty
# usage: ensure_tree_if_empty <root> <relpath1> <relpath2> ...
ensure_tree_if_empty() {
  root="$1"; shift
  mkdir -p "$root"
  if is_empty_dir "$root"; then
    # Build absolute paths; create with exact perms; then chown the whole root
    set -- $(printf "%s " "$@")  # normalize
    abs=""
    for rel in "$@"; do abs="$abs $root/$rel"; done
    install -d -m 0755 $abs
    chown -R "$WHMCS_WRITE_UID:$WHMCS_WRITE_GID" "$root"
    log "Initialized storage tree at $root"
  else
    log "$root has content, skipping storage init."
  fi
}

download_and_unpack_whmcs() {
  tmp="$(mktemp -d)"; dir="$tmp/unzip"; mkdir -p "$dir"

  if [ -z "$WHMCS_URL" ]; then
    log "Querying WHMCS Distributions API (type=${WHMCS_CHANNEL})..."
    # Returns JSON with keys including: url, sha256Checksum, releaseNotesUrl, changelogUrl
    # https://docs.whmcs.com/about-whmcs/whmcs-distributions/
    json="$(curl -fsSL "https://api1.whmcs.com/download/latest?type=${WHMCS_CHANNEL}")" || die "Failed to query Distributions API"
    url="$(echo "$json" | jq -r '.url')" || die "Failed to parse URL from API"
    sha="$(echo "$json" | jq -r '.sha256Checksum')" || sha=""
  else
    url="$WHMCS_URL"
    sha="$WHMCS_SHA256"
  fi

  [ -n "$url" ] && [ "$url" != "null" ] || die "No WHMCS download URL available"

  log "Downloading WHMCS package..."
  curl -fSL "$url" -o "$tmp/whmcs.zip" || die "Download failed"

  if [ -n "${sha:-}" ] && [ "$sha" != "null" ]; then
    echo "${sha}  $tmp/whmcs.zip" | sha256sum -c - || die "Checksum verification failed"
  else
    warn "No sha256Checksum provided, skipping verification."
  fi

  unzip -q "$tmp/whmcs.zip" -d "$dir" || die "Unzip failed"
  [ -d "$dir/whmcs" ] && src="$dir/whmcs" || src="$dir"

  mkdir -p "$WHMCS_WEB_ROOT"
  # Copy into the (empty) web root volume
  cp -a "$src"/. "$WHMCS_WEB_ROOT"/

  rm -rf "$tmp"
  log "WHMCS files installed to $WHMCS_WEB_ROOT"
}

main() {
  # Ensure roots exist
  mkdir -p "$WHMCS_WEB_ROOT" "$WHMCS_STORAGE_DIR"

  # 1) Seed WHMCS app into web root ONLY if empty
  if is_empty_dir "$WHMCS_WEB_ROOT"; then
    log "Empty $WHMCS_WEB_ROOT detected, fetching WHMCS..."
    download_and_unpack_whmcs
  else
    log "$WHMCS_WEB_ROOT has content, skipping WHMCS download."
  fi

  # 2) Create/chown storage tree ONLY if storage dir is empty
  #    Include both 'attachments' and 'attachments/projects' so the parent gets created too.
  ensure_tree_if_empty "$WHMCS_STORAGE_DIR" \
    attachments \
    attachments/projects \
    downloads \
    templates_c \
    whmcs_updater_tmp_dir

  # Done. Let the official nginx entrypoint continue (template render + nginx start)
  exit 0
}

main "$@"