FROM nginx:alpine
                                                                                                                                                                                            # --- Runtime tools used by the init script ---
# curl: fetch WHMCS; jq: parse JSON; unzip: extract; su-exec: drop root when needed
RUN apk add --no-cache curl jq unzip su-exec

# --- Template with custom variables ---
COPY config/default.conf.template /etc/nginx/templates/default.conf.template

# --- Init script: runs automatically on container start (before nginx) ---
COPY config/05-whmcs-fetch.sh /docker-entrypoint.d/05-whmcs-fetch.sh
RUN chmod +x /docker-entrypoint.d/05-whmcs-fetch.sh