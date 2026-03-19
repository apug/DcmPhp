#!/bin/sh
printf '%b\n' "--- PHP 7.4 Configuration ---" >&2

apps_dir="${DCM_VOLUMES_DIR}/DcmPhp/apps"
mkdir -p "$apps_dir"
printf '%b\n' "✓ Apps directory: $apps_dir" >&2
printf '%b\n' "" >&2
printf '%b\n' "Caddy usage example:" >&2
printf '%b\n' "  myapp.{\$CADDY_MAIN_DOMAIN} {" >&2
printf '%b\n' "    root * /var/www/html/myapp/public" >&2
printf '%b\n' "    php_fastcgi php74:9000" >&2
printf '%b\n' "    file_server" >&2
printf '%b\n' "    tls internal" >&2
printf '%b\n' "  }" >&2

# No config.partial variables needed — PHP-FPM ha solo impostazioni built-in
touch "$SERVICE_CONFIG_DIR/config.partial"
