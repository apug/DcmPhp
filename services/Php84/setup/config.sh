#!/bin/sh
printf '%b\n' "--- PHP 8.4 Configuration ---" >&2

apps_dir="${DCM_VOLUMES_DIR}/DcmPhp/apps"
mkdir -p "$apps_dir"
printf '%b\n' "✓ Apps directory: $apps_dir" >&2
printf '%b\n' "" >&2
printf '%b\n' "Caddy usage example:" >&2
printf '%b\n' "  myapp.{\$CADDY_MAIN_DOMAIN} {" >&2
printf '%b\n' "    root * /var/www/html/myapp/public" >&2
printf '%b\n' "    php_fastcgi php84:9000" >&2
printf '%b\n' "    file_server" >&2
printf '%b\n' "    tls internal" >&2
printf '%b\n' "  }" >&2

# No config.partial variables needed — PHP-FPM ha solo impostazioni built-in
touch "$SERVICE_CONFIG_DIR/config.partial"

if [ ! -f "$SERVICE_CONFIG_DIR/volumes.yml" ]; then
  cat > "$SERVICE_CONFIG_DIR/volumes.yml" <<'EOF'
# PHP 8.4 User-defined Volumes
#
# Aggiungi qui i volumi per montare le tue applicazioni nel container php84.
# Puoi aggiungere qualsiasi volume supportato da Docker Compose.
#
# Esempio:
#
# services:
#   php84:
#     volumes:
#       - /home/user/myapp:/var/www/html/myapp:z
#       - /home/user/otherapp:/var/www/html/otherapp:z
#
# Dopo ogni modifica: docker compose up -d --force-recreate php84

services:
  php84:
    volumes: []
EOF
  printf '%b\n' "✓ volumes.yml creato in $SERVICE_CONFIG_DIR" >&2
fi
