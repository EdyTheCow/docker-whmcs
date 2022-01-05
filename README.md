
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

## Moving Files Above Web Root

### File Storage

### Templates Cache

### Crons Directory

## Changing Configuration Permissions


# 🐛 Known issues

# 📜 Credits
- Logo created by Wob - [Dribbble.com/wob](https://dribbble.com/wob)
- Inspired by other similar projects [fauzie/docker-whmcs](https://github.com/fauzie/docker-whmcs), [cloudlinux/kd-whmcs](https://github.com/cloudlinux/kd-whmcs) and [darthsoup/docker-whmcs](https://github.com/darthsoup/docker-whmcs)
