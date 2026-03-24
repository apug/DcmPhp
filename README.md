# DcmPhp

PHP-FPM services for [Docker Collection Manager](https://github.com/andreabassi/docker-collection-manager).
Provides PHP 7.4, 8.3, 8.4 and 8.5 as independent services, each built from a shared base image.

## Services

| Service | Image          | PHP Version |
|---------|----------------|-------------|
| php74   | dcm-php:7.4    | 7.4         |
| php83   | dcm-php:8.3    | 8.3         |
| php84   | dcm-php:8.4    | 8.4         |
| php85   | dcm-php:8.5    | 8.5         |

All services run as **www-data** mapped to your host UID/GID, so files created inside the container are owned by your user.

## PHP Extensions

Installed in every image:

`amqp` `bcmath` `gd` `gettext` `imap` `intl` `ldap` `mysqli` `odbc` `opcache`
`pdo_mysql` `pdo_odbc` `pdo_pgsql` `pgsql` `soap` `sockets` `sodium` `sourceguardian`
`uuid` `yaml` `zip`

Composer is installed globally at `/usr/local/bin/composer`.

## php.ini defaults

| Setting                           | Value   |
|-----------------------------------|---------|
| upload_max_filesize               | 64M     |
| post_max_size                     | 64M     |
| memory_limit                      | 256M    |
| max_execution_time                | 120     |
| opcache.enable                    | 1       |
| opcache.memory_consumption        | 128     |
| opcache.interned_strings_buffer   | 8       |
| opcache.max_accelerated_files     | 10000   |
| opcache.revalidate_freq           | 2       |

## Volume mounts

Each service mounts a shared apps directory:

```
${DCM_VOLUMES_DIR}/DcmPhp/apps  →  /var/www/html  (inside the container)
```

To mount individual projects, edit the generated `volumes.yml` in your config directory:

```
${DCM_CONFIG_DIR}/DcmPhp/Php83/volumes.yml
```

Example:

```yaml
services:
  php83:
    volumes:
      - /home/user/myapp:/var/www/html/myapp:z
      - /home/user/otherapp:/var/www/html/otherapp:z
```

After any change: `docker compose up -d --force-recreate php83`

## Caddy integration

DcmPhp services sit on the `web` network alongside the Base/Caddy service.
Each PHP service exposes FastCGI on port 9000 under its service name.

Add a site block to your Caddy config (typically managed via the Base/Caddy service):

```caddyfile
myapp.{$CADDY_MAIN_DOMAIN} {
    root * /var/www/html/myapp/public
    php_fastcgi php83:9000
    file_server
    tls internal
}
```

Replace `php83` with the service name matching the PHP version you want to use.

### Multiple apps on different PHP versions

```caddyfile
# App on PHP 8.3
app1.{$CADDY_MAIN_DOMAIN} {
    root * /var/www/html/app1/public
    php_fastcgi php83:9000
    file_server
    tls internal
}

# Legacy app on PHP 7.4
legacy.{$CADDY_MAIN_DOMAIN} {
    root * /var/www/html/legacy/public
    php_fastcgi php74:9000
    file_server
    tls internal
}
```

### WordPress example

```caddyfile
wp.{$CADDY_MAIN_DOMAIN} {
    root * /var/www/html/wp

    php_fastcgi php84:9000

    file_server

    @notFound {
        not file
        not path /wp-admin/*
    }
    rewrite @notFound /index.php

    tls internal
}
```

## Quick start

```bash
# Enable one or more PHP services
dcm service enable DcmPhp/Php83

# Build and start
docker compose up -d --build php83

# Enter the container (drops in as your host user)
docker exec -it php83 sh

# Run Composer inside the container
docker exec php83 composer install -d /var/www/html/myapp
```

## Networks

| Network | Purpose                        |
|---------|--------------------------------|
| web     | HTTP/HTTPS — shared with Caddy |
| db      | Database — shared with DB services |
