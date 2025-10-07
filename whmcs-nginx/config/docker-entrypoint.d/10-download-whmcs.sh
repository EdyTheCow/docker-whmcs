#!/bin/sh
set -eu; (set -o pipefail 2>/dev/null) && set -o pipefail
. /usr/local/lib/whmcs-lib.sh

mkdir -p "$WHMCS_WEB_ROOT"
if is_empty_dir "$WHMCS_WEB_ROOT"; then
  log "Empty $WHMCS_WEB_ROOT; fetching WHMCS…"
  fetch_whmcs_into "$WHMCS_WEB_ROOT"
else
  log "$WHMCS_WEB_ROOT has content; skipping download."
fi