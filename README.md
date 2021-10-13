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


# 🔒 Security Hardening

## Moving Files Above Web Root

### File Storage

### Templates Cache

### Crons Directory

## Changing Configuration Permissions


# 🐛 Known issues

# 📜 Credits
- Logo created by Wob - [Dribbble.com/wob](https://dribbble.com/wob)
- Inspired by other similar projects [fauzie/docker-whmcs](https://github.com/fauzie/docker-whmcs) and [cloudlinux/kd-whmcs](https://github.com/cloudlinux/kd-whmcs)
