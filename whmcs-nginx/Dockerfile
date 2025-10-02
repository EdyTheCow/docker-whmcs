FROM nginx:alpine

# Static main config
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Site template → auto-rendered at startup by envsubst
COPY nginx/sites/default.conf.template /etc/nginx/templates/default.conf.template