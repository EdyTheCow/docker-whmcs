
<p align="center">
  <img width="400" src="https://raw.githubusercontent.com/BeefBytes/Assets/master/Other/container_illustration/v2/dockerized_whmcs.png">
</p>

# 📚 About
The point of this project is a production ready solution for running WHMCS in docker under Traefik reverse proxy. There's already a couple other projects attempting something similar. However, they are either meant for development only, are outdated and/or not optimized to be ran under Traefik. This project complies with all of the official WHMCS security and packages recommendations that are found at ["Further Security Steps"](https://docs.whmcs.com/Further_Security_Steps) and ["System Environment Guide"](https://docs.whmcs.com/System_Environment_Guide).

> [!NOTE]  
> This exact installation is currently being used in live production. It is being actively maintained and tested. PRs, suggestions and issue reports are more than welcome.

# 🧰 Getting Started
This project uses Nginx instead of Apache as a web server, WHMCS was developed with Apache in mind so few extra steps are required to achieve production ready setup. Majority of modifications have been already implemented, rest of manual modifications are covered in the guide below.

## Requirements
- Domain
- Valid WHMCS license

# 🏗️ Installation
<b>Clone repository</b>
```
git clone https://github.com/EdyTheCow/docker-whmcs.git
```

<b>Set correct acme.json permissions</b><br />
Navigate to `_base/data/traefik/` and run:
```
sudo chmod 600 acme.json
```

<b>Create docker network</b><br />
```
docker network create docker-whmcs-network
```

<b>Generate .htpasswd user and password</b><br />
Navigate to `_base/data/traefik/.htpasswd` and place your htpasswd user/password there.

To generate `.htpasswd` credentials you can use this one-liner command. It uses the official Apache docker image from official source on Docker Hub.
```
docker run --rm --entrypoint htpasswd httpd:latest -Bbn <username> <password> > .htpasswd
```

Once done, whenever you navigate to your whmcs admin area, you'll have to login with credentials you just generated and then login with your WHMCS admin user. This basic auth is very effective against bots and endless spam in emails of attempted and failed logins. This only applies for admin page of WHMCS, regular users won't be affected.

<b>Start docker compose</b><br />
Inside of `_base/compose` run the command below. This will start Traefik reverse proxy.
 ```
docker-compose up -d
 ```

<b>Configure Nginx default.conf</b><br />
Navigate to `whmcs/data/nginx/sites/default.conf` and replace these variable:
| Variable          | Example                 | Description                                                                                       |
|-------------------|-------------------------|---------------------------------------------------------------------------------------------------|
| YOUR_DOMAIN       | portal.domain.com       | Domain for WHMCS installtation                                                                    |
| YOUR_TRAEFIK_SUBNET   | 172.17.0.0/16           | It's normally 172.17.x.x or 172.18.x.x you can find it by running docker inspect on the traefik container and looking for `docker-whmcs-network` |
| IP_OF_YOUR_SERVER | Public IP of the server | This is used to verify the WHMCS license                                                          |

If you're still unsure about your Traefik's subnet, set it as example value shown above for now. Then later on once WHMCS is running navigate to `System Logs > Admin Log` and you'll see IP Address. It should look something like `172.18.0.2` or similar. We're interested in the second number. So if the IP shown was `172.18.0.2` the subnet that should be set as: `172.18.0.0/16`. Restart and check the logs again, this time your real IP should be displayed.

<b>Place contents of WHMCS files</b><br />
Navigate to `whmcs/data/whmcs` and place the contents of WHMCS you downloaded from whmcs.com in there.

<b>Set .env variables for WHMCS</b><br />
Navigate to `whmcs/compose/.env` and set these variables:
| Variable            | Example             | Description                                      |
|---------------------|---------------------|--------------------------------------------------|
| DOMAIN              | portal.domain.com   | Domain for WHMCS installtation                   |
| MYSQL_PASSWORD      | MySQL user password | Generate a password for your mysql user          |
| MYSQL_ROOT_PASSWORD | MySQL root password | Do not use the same password, generate a new one |

<b>Start docker compose</b><br />
Inside of `whmcs/compose` run the command below. This will start WHMCS and rest of the services.
 ```
docker compose up -d
 ```
Now you can navigate to `your-domain.com/install` and follow the installation insturctions. Use `mysql` for MySQL host. User, database name and password are found in `whmcs/compose/.env` where you configured them earlier.

After installation delete the install folder in `whmcs/data/whmcs/install` and follow the instruction below for additional configuration for security hardening.

# 🔒 Security Hardening
Make sure to complete all of the steps below! After you have completed all of the steps, you should be ideally left with two warning and none "Needing Attention" complaints inside "System Health" tab. One warning complaining about it running Nginx instead of Apache (this is safe to ignore). The other complaining about usage of default template names. This is also safe to ignore, but linked documentation should be read if you plan on customizing templates to follow the best practices.

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

Navigate to `Settings` tab and replace the old paths with the newly added ones.

### Templates Cache
Official source: [docs.whmcs.com](https://docs.whmcs.com/Further_Security_Steps#Templates_Cache) <br />
Navigate to `whmcs/data/whmcs/configuration.php` and change path for `$templates_compiledir` to `/var/www/whmcs_storage/templates_c`

### Crons Directory
Official source: [docs.whmcs.com](https://docs.whmcs.com/Further_Security_Steps#Move_the_Crons_Directory) <br />
1. Navigate to `whmcs/data/whmcs` and move `crons` directory to `whmcs/data/whmcs_storage`. <br />
2. Navigate to `whmcs/data/whmcs_storage/crons` and edit `config.php.new`, inside the config uncomment the `whmcspath` option and set the new path to `/var/www/html/`. <br />
3. Rename the `config.php.new` to `config.php`. 
4. Navigate to `whmcs/data/whmcs/configuration.php` and add this line at the bottom of the configuration `$crons_dir = '/var/www/whmcs_storage/crons/';`

If done correctly, crons should be now located outside web root and system set to look for new crons location as recommended by WHMCS.

### eMail Import Cron (optional)
Official source: [docs.whmcs.com](https://docs.whmcs.com/Email_Importing) <br />
Navigate to `whmcs/compose` and edit `docker-compose.yml`, inside the file uncomment the two commands under the ofelia-labels.<br />
Rebuild stack with `docker compose down && docker compose up -d`.

## Setting update folder
Official source: [help.whmcs.com](https://help.whmcs.com/m/updating/l/678178-configuring-the-temporary-path) <br />
Setting update folder will allow you to automatically update WHMCS in the future. Similar to file storage the update folder will be located above the web root inside `whmcs_storage` directory.
Navigate to `Automation Status (gear icon) > Update WHMCS > Configure Update Settings` and set the directory to `/var/www/whmcs_storage/whmcs_updater_tmp_dir`

# 🐛 Known issues

# 📝 Planned
- Create and test an alternative installation with Apache web server
- Create a ready to deploy Dokploy docker compose example

# 📜 Credits
- Logo created by Wob - [Dribbble.com/wob](https://dribbble.com/wob)
- Inspired by other similar projects [fauzie/docker-whmcs](https://github.com/fauzie/docker-whmcs), [cloudlinux/kd-whmcs](https://github.com/cloudlinux/kd-whmcs) and [darthsoup/docker-whmcs](https://github.com/darthsoup/docker-whmcs)
