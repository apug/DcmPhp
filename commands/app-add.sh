# DESCRIPTION: Add a PHP app: volumes on Caddy and PHP service, Caddy site config

set -euo pipefail

usage() {
  echo "Usage: dcm run DcmPhp app-add <PhpService> <domain> <host-path>"
  echo ""
  echo "  PhpService  PHP service name (e.g. Php83, Php84)"
  echo "  domain      Full domain for the app (e.g. app1.apug.it)"
  echo "  host-path   Absolute path to the app on the host"
  echo ""
  echo "Example:"
  echo "  dcm run DcmPhp app-add Php83 app1.apug.it /home/andrea/projects/app1"
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [ $# -lt 3 ]; then
  echo "Error: missing arguments." >&2
  echo "" >&2
  usage >&2
  exit 1
fi

php_service="$1"  # e.g. Php83
domain="$2"       # e.g. app1.apug.it
host_path="$3"    # e.g. /home/andrea/projects/app1

# Validate required DCM context variables
: "${DCM_CONFIG_DIR:?DCM_CONFIG_DIR not set — run via dcm run}"
: "${DCM_PROXY_SERVICE:?DCM_PROXY_SERVICE not set — run via dcm run}"
: "${DCM_BIN:?DCM_BIN not set — run via dcm run}"
: "${DCM_REPOS_DIR:?DCM_REPOS_DIR not set — run via dcm run}"

# Validate PHP service exists in the repo
php_service_dir="$DCM_REPOS_DIR/DcmPhp/services/$php_service"
if [ ! -d "$php_service_dir" ]; then
  echo "Error: PHP service '$php_service' not found at $php_service_dir" >&2
  echo "Available services: $(ls "$DCM_REPOS_DIR/DcmPhp/services/" | tr '\n' ' ')" >&2
  exit 1
fi

# Container service name: lowercase (Php83 → php83)
container_name="${php_service,,}"

# App name from host path basename
app_name=$(basename "$host_path")

# Container mount path
container_path="/var/www/html/$app_name"

# Volume line (indented for volumes.yml)
volume_entry="      - $host_path:$container_path:z"

# -------------------------------------------------------
# add_volume_entry <file> <entry>
# Adds <entry> to the volumes list in a volumes.yml file.
# Handles both 'volumes: []' (empty) and existing list.
# -------------------------------------------------------
add_volume_entry() {
  local file="$1"
  local entry="$2"
  local host_part
  host_part=$(echo "$entry" | sed 's/^ *//' | cut -d: -f1 | sed 's/^- //')

  if [ ! -f "$file" ]; then
    echo "Error: volumes file not found: $file" >&2
    echo "Run 'dcm service config' first to initialize service configuration." >&2
    return 1
  fi

  # Already present?
  if grep -qF "$host_part" "$file"; then
    echo "  Volume already present in $(basename "$(dirname "$file")")/$(basename "$file"), skipping."
    return 0
  fi

  if grep -q 'volumes: \[\]' "$file"; then
    # Replace empty list with the first entry
    sed -i "s|volumes: \[\]|volumes:\n${entry}|" "$file"
  else
    # Append after the last volume entry line
    awk -v e="$entry" '
      BEGIN { last=0 }
      /^      - / { last=NR }
      { lines[NR]=$0 }
      END {
        for (i=1; i<=NR; i++) {
          print lines[i]
          if (i==last) print e
        }
      }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
  fi
}

# -------------------------------------------------------
# 1. Add volume to Caddy volumes.yml
# -------------------------------------------------------
caddy_volumes="$DCM_CONFIG_DIR/$DCM_PROXY_SERVICE/volumes.yml"
echo "→ Adding volume to Caddy ($caddy_volumes)..."
add_volume_entry "$caddy_volumes" "$volume_entry"
echo "  ✓ $host_path:$container_path:z"

# -------------------------------------------------------
# 2. Add volume to PHP service volumes.yml
# -------------------------------------------------------
php_volumes="$DCM_CONFIG_DIR/DcmPhp/$php_service/volumes.yml"
echo "→ Adding volume to $php_service ($php_volumes)..."
add_volume_entry "$php_volumes" "$volume_entry"
echo "  ✓ $host_path:$container_path:z"

# -------------------------------------------------------
# 3. Add Caddy site block to Caddyfile.After
# -------------------------------------------------------
echo "→ Adding Caddy site block for $domain..."

caddy_snippet=$(cat <<EOF
$domain {
  root * $container_path/public
  php_fastcgi $container_name:9000
  file_server
  tls internal
}
EOF
)

tmp_snippet=$(mktemp /tmp/dcm-caddy-snippet-XXXXXX.caddy)
printf '%s\n' "$caddy_snippet" > "$tmp_snippet"

"$DCM_BIN" caddy add "$app_name" --target after --file "$tmp_snippet"
rm -f "$tmp_snippet"

echo ""
echo "✓ App '$app_name' configured:"
echo "  Domain:    $domain"
echo "  PHP:       $container_name:9000"
echo "  App path:  $host_path → $container_path"
echo ""
echo "Restart services to apply:"
echo "  dcm service restart caddy $container_name"
