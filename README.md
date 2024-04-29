
<p align="center">
  <img width="400" src="https://raw.githubusercontent.com/BeefBytes/Assets/master/Other/container_illustration/v2/dockerized_whmcs.png">
</p>

# 📚 About
The point of this project is a production ready solution for running WHMCS in docker under Traefik reverse proxy. There's already a couple other projects attempting something similar. However, they are either meant for development only, are outdated and/or not optimized to be ran under Traefik. This project complies with all of the official WHMCS security and packages recommendations that are found at ["Further Security Steps"](https://docs.whmcs.com/Further_Security_Steps) and ["System Environment Guide"](https://docs.whmcs.com/System_Environment_Guide).

# 🧰 Getting Started
This project uses Nginx instead of Apache web server, WHMCS was development with Apache in mind so few extra steps are required to achieve production ready setup. Majority of modifications have been already implemented, rest of manual modifications are covered in the guide below.

## Requirements
- Domain
- Valid WHMCS license

# 🏗️ Installation
<b>Clone repository</b>
```
git clone https://github.com/EdyTheCow/docker-whmcs.git
```

<b>Set correct acme.json permissions</b><br />
Navigate to `_base/data/traefik/` and run
```
sudo chmod 600 acme.json
```

<b>Generate .htpasswd user and pass</b><br />
Navigate to `_base/data/traefik/.htpasswd` and place your generated user/pass in there

Whenever you navigate to your admin area, you'll have to login with generated user and pass and then login with your WHMCS user. This basic auth is very effective against bots and endless spam in emails of failed logins.

<b>Start docker compose</b><br />
Inside of `_base/compose` run
 ```
docker-compose up -d
 ```

<b>Configure Nginx default.conf</b><br />
Navigate to `whmcs/data/nginx/sites/default.conf` and change these variable:
| Variable          | Example                 | Description                                                                                       |
|-------------------|-------------------------|---------------------------------------------------------------------------------------------------|
| YOUR_DOMAIN       | portal.domain.com       | Domain for WHMCS installtation                                                                    |
| YOUR_TRAEFIK_IP   | 172.17.0.0/16           | It's normally 172.17.x.x or 172.18.x.x you can find it by running docker inspect on the traefik container |
| IP_OF_YOUR_SERVER | Public IP of the server | This is used to verify the WHMCS license                                                          |

<b>Place contents of WHMCS files</b><br />
Navigate to `whmcs/data/whmcs` and place the contents of WHMCS in there

<b>Set .env variables for WHMCS</b><br />
Navigate to `whmcs/compose/.env` and set these variables:
| Variable            | Example             | Description                                      |
|---------------------|---------------------|--------------------------------------------------|
| DOMAIN              | portal.domain.com   | Domain for WHMCS installtation                   |
| MYSQL_PASSWORD      | MySQL user password | Generate a password for your mysql user          |
| MYSQL_ROOT_PASSWORD | MySQL root password | Do not use the same password, generate a new one |

<b>Start docker compose</b><br />
Inside of `whmcs/compose` run
 ```
docker-compose up -d
 ```
Now you can navigate to `your-domain.com/install` and follow the installation insturctions. Use `mysql` for MySQL host. User, database and password are found in `whmcs/compose/.env` where you configured them earlier.

After installation delete the install folder in `whmcs/data/whmcs/install` and follow the instruction below for additional configuration for security hardening.

# 🔒 Security Hardening

### Changing Configuration Permissions
Official source: [docs.whmcs.com](https://docs.whmcs.com/Further_Security_Steps#Secure_the_configuration.php_File) <br />
Navigate to `whmcs/data/whmcs` and run 
```
sudo chmod 400 configuration.php
```

### Setting correct URL
Official source: [docs.whmcs.com](https://docs.whmcs.com/Further_Security_Steps#Enable_SSL) <br />
Sometimes the URL in admin panel might be using http instead of https which may cause a warning for invalid SSL certificate.
In the WHMCS panel navigate to `System Setting > General Settings` and make sure `Domain` and `WHMCS System URL` are using https.

## Moving Files Above Web Root
Moving files above web root is a recommended practice by official WHMCS documentation. This is fairly easy to do using docker volumes. 
The volume `whmcs_storage` is used for this exact purpose, directories have been already created so all you need to do is change them in the admin panel.

### File Storage
Official source: [docs.whmcs.com](https://docs.whmcs.com/Further_Security_Steps#File_Storage) <br />
Navigate to `System Setting > Storage Settings` under `Configurations` add listed local storage:
| Path                                        |
|---------------------------------------------|
| /var/www/whmcs_storage/downloads            |
| /var/www/whmcs_storage/attachments          |
| /var/www/whmcs_storage/attachments/projects |

Navigate to `Settings` tab and replace tbe old paths with the newly added ones.

### Templates Cache
Official source: [docs.whmcs.com](https://docs.whmcs.com/Further_Security_Steps#Templates_Cache) <br />
Navigate to `whmcs/data/whmcs/configuration.php` and add change path for `$templates_compiledir` to `/var/www/whmcs_storage/templates_c`

### Crons Directory
Official source: [docs.whmcs.com](https://docs.whmcs.com/Further_Security_Steps#Move_the_Crons_Directory) <br />
Navigate to `whmcs/data/whmcs` and move `crons` directory to `whmcs/data/whmcs_storage`. <br />
Navigate to `crons` and edit `config.php.new`, inside the config uncomment the `whmcspath` option and set the new path to `/var/www/html/`. <br />
Rename the `config.php.new` to `config.php`. Navigate to `whmcs/data/whmcs/configuration.php` and add this line at the bottom of the configuration `$crons_dir = '/var/www/whmcs_storage/crons/';` <br />
Uncomment 'crons/pop.php' in 'whmcs/compose/docker-compose.yml' to activate email import to tickets. Don't forget to rebuild the containers with 'docker-compose up -d' after that.

## Setting update folder
Official source: [help.whmcs.com](https://help.whmcs.com/m/updating/l/678178-configuring-the-temporary-path) <br />
Setting update folder will allow you to automatically update WHMCS in the future. Similar to file storage the update folder will be located above the web root inside `whmcs_storage` directory.
Navigate to `Utilities > Update WHMCS` and set the directory to `/var/www/whmcs_storage/whmcs_updater_tmp_dir`

# 🐛 Known issues

# Troubleshooting
Sometimes after an update the containers need a rebuild. Switch to the directory 'whmcs/compose' and run 'docker-compose down' and 'docker-compose up -d'. Please keep in mind that this leads to a short downtime.

# 📜 Credits
- Logo created by Wob - [Dribbble.com/wob](https://dribbble.com/wob)
- Inspired by other similar projects [fauzie/docker-whmcs](https://github.com/fauzie/docker-whmcs), [cloudlinux/kd-whmcs](https://github.com/cloudlinux/kd-whmcs) and [darthsoup/docker-whmcs](https://github.com/darthsoup/docker-whmcs)
