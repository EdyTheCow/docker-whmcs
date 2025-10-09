FROM nginx:alpine

# --- Runtime tools used by the init script ---
# curl: fetch WHMCS; jq: parse JSON; unzip: extract; su-exec: drop root when needed
RUN apk add --no-cache curl jq unzip su-exec

# --- Template with custom variables ---
COPY config/default.conf.template /etc/nginx/templates/default.conf.template

# --- Library with shared helpers ---
COPY config/whmcs-lib.sh /usr/local/lib/whmcs-lib.sh

# --- Post WHMCS installation configuration script (optional, can be done manually too) ---
COPY config/whmcs-post-install-config.sh /usr/local/bin/whmcs-post-install-config.sh
RUN chmod +x /usr/local/bin/whmcs-post-install-config.sh

# --- Modular init scripts (executed in sorted order by the official entrypoint) ---
COPY config/docker-entrypoint.d/*.sh /docker-entrypoint.d/
RUN chmod +x /docker-entrypoint.d/*.sh