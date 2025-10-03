# WHMCS Docker Images
These docker images are built and published using Github Actions workflows. You can inspect the workflows themselves in `.github/workflows/`.

## whmcs-php-fpm
This image is built on top of official php-fpm image found on Docker Hub. It takes care of all the dependencies required to run WHMCS, the included dependencies are based on official WHMCS documentation.

## whmcs-nginx
This image is built on top of official nginx image found on Docker Hub. It currently only copies over `nginx.conf` and generates `default.conf` based on a template. 
This allows us to pass variables down to template when container is started. Which makes configuration easier than having to edit the file itself manually.
