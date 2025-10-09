# WHMCS Docker Images
These docker images are built and published using Github Actions workflows. You can inspect the workflows themselves in `.github/workflows/`.

## whmcs-php-fpm
This image is built on top of official php-fpm image found on Docker Hub. It takes care of all the dependencies required to run WHMCS, the included dependencies are based on official WHMCS documentation and recommendations. Few configs are included with sensible default values.

## whmcs-nginx
This image is built on top of official nginx image found on Docker Hub. It includes a default.conf template with variables, allowing for configuration without having to edit the file itself. Scripts are also included which download WHMCS files using API and create directories outside web root according to WHMCS recommendations. Downloading of WHMCS and folder creation will only execute if directory is empty (ignores .gitignore), otherwise it will skip.

### File structure
The scripts are split up into smaller steps found under `whmcs-nginx/config/docker-entrypoint.d`. Each script uses `whmcs-nginx/config/whmcs-lib.sh` as a library, this file includes all of the logic, variables and functions. All of the scripts under `docker-entrypoint.d` folder are ran automatically with nginx docker image built in entrypoint. 

Script `whmcs-nginx/config/whmcs-post-install-config.sh` is an optional post-installation automated configuration:
- Moves crons folder from web root to whmcs_storage folder and updates configs to reflect new location
- Changes location of templates_c folder to whmcs_storage by updating configuration.php
- Deletes install folder
- Sets chmod 400 permissions on configuration.php

All of these steps are required, you can choose for yourself if you want to do them manually or use the script. Both methods are documented in the main README file.

### Available variables
**Found in `whmcs-nginx/config/default.conf.template`**

| Variable         | Default value | Description                                                                                                                                                        |
| ---------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| NGINX_DOMAIN     | ${DOMAIN}     | Domain used for nginx default.conf. In docker-compose this is automatically set with ${DOMAIN} variable in `.env` you don't need to additionally set this variable |
| TRAEFIK_SUBNET   |               | Used as trust proxy IP so it passes down the real user's IP                                                                                                        |
| PUBLIC_SERVER_IP |               | Used by WHMCS to record an IP for the license. Recommended to set it, otherwise container IP is used and that can change between restarts                          |

**Found in `whmcs-nginx/config/whmcs-lib.sh`**

| Variable          | Default value          | Description                                                                                             |
| ----------------- | ---------------------- | ------------------------------------------------------------------------------------------------------- |
| WHMCS_WEB_ROOT    | /var/www/html          | Location where WHMCS files will be downloaded and stored                                                |
| WHMCS_STORAGE_DIR | /var/www/whmcs_storage | Location for folders that are recommended to be outside web root. Such as: `attachments`, `crons`, etc. |
| WHMCS_WRITE_UID   | 33                     | User that will own files found in `WHMCS_WEB_ROOT` and `WHMCS_STORAGE_DIR` locations                    |
| WHMCS_WRITE_GID   | 33                     | Group that will own files found in `WHMCS_WEB_ROOT` and `WHMCS_STORAGE_DIR` locations                   |
| WHMCS_URL         |                        | Override download URL of WHMCS files                                                                    |
| WHMCS_SHA256      |                        | Check against a specific checksum                                                                       |
| WHMCS_CHANNEL     | stable                 | Branch used to download WHMCS files from API                                                            |