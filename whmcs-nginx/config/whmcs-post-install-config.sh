#!/bin/sh
set -eu; (set -o pipefail 2>/dev/null) && set -o pipefail
. /usr/local/lib/whmcs-lib.sh

# 1) Move crons/ to whmcs_storage and update configs ($whmcspath in crons/config.php, $crons_dir in configuration.php)
move_crons_to_storage

# 2) Relocate templates_c to whmcs_storage by updating configuration.php ($templates_compiledir) to new path
set_templates_location

# 3) Delete the install directory (required post-installaion)
delete_install_dir

# 4) Set configuration.php permissions to 400 (owner-read only)
set_configuration_mode_400

log "Post-install configuration done!"