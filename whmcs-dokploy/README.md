# WHMCS - Dokploy

# 📚 About
This is a ready to use docker compose for Dokploy compose service demployment. You only need to follow instructions below for installation and deployment of WHMCS in Dokploy.

# 🧰 Getting Started
Dokploy docker compose uses the same docker images as the regular install. You are required to complete essentialy the same steps with difference being Dokploy.
If you are confused about any of non Dokploy related steps, check out the main README for more detailed explanations.

## Requirements
- Domain
- Valid WHMCS license
- Working instance of Dokploy

# 🏗️ Installation

1. Navigate to `Create service > Compose` fill out name, select server, etc.
2. Navigate to tab `Raw` and copy / paste the contents of `whmcs-dokploy/docker-compose.yml`, click `Save`
3. Navigate to `Environment` tab and copy / paste the contents of `whmcs-dokploy/.env`. Fill out all of the variables. You can leave `TRAEFIK_SUBNET` empty for now. Click `Save`
4. Navigate to `Domains` tab, click `Add Domain` (your domain has to be pointing at the IP of server you selected earlier when creating service). Select these values:

| Field             | Value                         |
| ----------------- | ----------------------------- |
| Service name      | nginx                         |
| Container port    | mysql                         |
| HTTPS             | Let's Encrypt                 |

5. Navigate to `Advanced` tab, scroll down to `Enable Isolated Deployment`. Toggle this option on and click `Save`
6. `Deploy` the service
7. Navigate to domain you selected in your browser and do the initial installation

| Field             | Default value                 |
| ----------------- | ----------------------------- |
| License Key       | Found in whmcs.com            |
| Database Host     | mysql                         |
| Database Username | whmcs                         |
| Database Password | Found in `Environment` tab    |
| Database Name     | whmcs                         |

8. Once you reach screen asking you to delete `install` directory. Navigate to `Terminal` in Dokploy, select `/bin/sh` and run this command:

```sh
sh -lc '/usr/local/bin/whmcs-post-install-config.sh'
```
9. Go back to your browser and refresh the page, now you should be able to login
10. Complete the rest of post-installation steps below

## Post-installation steps

### Setting update folder
Official source: [help.whmcs.com](https://help.whmcs.com/m/updating/l/678178-configuring-the-temporary-path) <br />
Setting update folder will allow you to automatically update WHMCS in the future. Similar to file storage the update folder will be located above the web root inside `whmcs_storage` directory.
Navigate to `Automation Status (gear icon) > Update WHMCS > Configure Update Settings` and set the directory to `/var/www/whmcs_storage/whmcs_updater_tmp_dir`

### Moving Files Above Web Root
Moving files above web root is a recommended practice by official WHMCS documentation. This is fairly easy to do using docker volumes. 
The volume `whmcs_storage` is used for this exact purpose, directories have been already created so all you need to do is change them in the admin panel.

#### File Storage
Official source: [docs.whmcs.com](https://docs.whmcs.com/Further_Security_Steps#File_Storage) <br />
Navigate to `System Setting > Storage Settings` under `Configurations` add listed local storage:
| Path                                        |
|---------------------------------------------|
| /var/www/whmcs_storage/downloads            |
| /var/www/whmcs_storage/attachments          |
| /var/www/whmcs_storage/attachments/projects |

Navigate to `Settings` tab and replace the old paths with the newly added ones.
