#!/bin/sh
set -eu; (set -o pipefail 2>/dev/null) && set -o pipefail
. /usr/local/lib/whmcs-lib.sh

ensure_tree_if_empty "$WHMCS_STORAGE_DIR" \
  attachments \
  attachments/projects \
  downloads \
  templates_c \
  whmcs_updater_tmp_dir