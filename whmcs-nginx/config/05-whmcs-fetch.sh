#!/bin/sh
set -e

: "${WHMCS_WEB_ROOT:=/var/www/html}"
: "${WHMCS_CHANNEL:=stable}"
: "${WHMCS_URL:=}"
: "${WHMCS_SHA256:=}"
: "${WHMCS_WRITE_UID:=33}" # Debian www-data
: "${WHMCS_WRITE_GID:=33}"

log() { echo "[whmcs-init] $*"; }

is_empty_dir() {
  # empty if no entries (ignores . and ..)
  [ -z "$(ls -A "$WHMCS_WEB_ROOT" 2>/dev/null || true)" ]
}

download_and_unpack() {
  tmp="$(mktemp -d)"; dir="$tmp/unzip"; mkdir -p "$dir"

  if [ -z "$WHMCS_URL" ]; then
    log "Querying WHMCS Distributions API (type=${WHMCS_CHANNEL})..."
    # Returns: version, url, sha256Checksum, releaseNotesUrl, changelogUrl
    json="$(curl -fsSL "https://api1.whmcs.com/download/latest?type=${WHMCS_CHANNEL}")"
    url="$(echo "$json" | jq -r '.url')"
    sha="$(echo "$json" | jq -r '.sha256Checksum')"
  else
    url="$WHMCS_URL"
    sha="$WHMCS_SHA256"
  fi

  [ -n "$url" ] && [ "$url" != "null" ] || { echo "[whmcs-init] ERROR: no download URL"; exit 1; }

  log "Downloading WHMCS: $url"
  curl -fSL "$url" -o "$tmp/whmcs.zip"

  if [ -n "$sha" ] && [ "$sha" != "null" ]; then
    echo "${sha}  $tmp/whmcs.zip" | sha256sum -c -
  else
    log "WARNING: no sha256Checksum provided; skipping verification."
  fi

  unzip -q "$tmp/whmcs.zip" -d "$dir"
  [ -d "$dir/whmcs" ] && src="$dir/whmcs" || src="$dir"

  # Ensure target exists
  mkdir -p "$WHMCS_WEB_ROOT"

  # Copy files into the (empty) volume
  cp -a "$src"/. "$WHMCS_WEB_ROOT"/

  # Create WHMCS writable dirs for php-fpm container
  #install -d -m 0755 "$WHMCS_WEB_ROOT/attachments" \
  #                   "$WHMCS_WEB_ROOT/downloads" \
  #                   "$WHMCS_WEB_ROOT/templates_c"
  #chown -R "$WHMCS_WRITE_UID":"$WHMCS_WRITE_GID" \
  #        "$WHMCS_WEB_ROOT/attachments" \
  #        "$WHMCS_WEB_ROOT/downloads" \
  #        "$WHMCS_WEB_ROOT/templates_c"

  rm -rf "$tmp"
}

# -------- main --------
mkdir -p "$WHMCS_WEB_ROOT"

if is_empty_dir; then
  log "Empty ${WHMCS_WEB_ROOT}; fetching & installing WHMCS files..."
  download_and_unpack
else
  log "${WHMCS_WEB_ROOT} has content; skipping WHMCS download."
fi

# Let the official entrypoint continue (renders templates, then starts nginx)
exit 0