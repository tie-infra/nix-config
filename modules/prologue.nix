{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.prologue;

  src = pkgs.fetchFromGitHub {
    owner = "michaelstaake";
    repo = "Prologue";
    rev = "v${cfg.version}";
    hash = cfg.srcHash;
  };

  phpPackage = pkgs.php85.withExtensions (
    { enabled, all }:
    enabled
    ++ (with all; [
      gd
      pdo_mysql
      mbstring
      fileinfo
    ])
  );

  configFile = pkgs.writeText "prologue-config.php" ''
    <?php
    $db_host = '${cfg.database.host}';
    $db_user = '${cfg.database.user}';
    $db_pass = file_get_contents('${config.sops.secrets."prologue/db-password".path}');
    $db_name = '${cfg.database.name}';

    $app_url = '${cfg.appUrl}';
    $app_subfolder = "";
    $app_name = '${cfg.appName}';
    $storage_filesystem_root = '${cfg.stateDir}/storage';
    $log_directory = '${cfg.stateDir}/storage/logs';

    $csrf_secret = file_get_contents('${config.sops.secrets."prologue/csrf-secret".path}');

    function base_url($path = "") {
      global $app_url, $app_subfolder;
      return rtrim($app_url, "/") . "/" . ltrim($app_subfolder . "/" . ltrim($path, "/"), "/");
    }

    function base_path($path = "") {
      global $app_subfolder;
      return "/" . ltrim($app_subfolder . "/" . ltrim($path, "/"), "/");
    }
  '';

  setupScript = pkgs.writeShellScript "prologue-setup" ''
    set -eu
    stateDir="${cfg.stateDir}"
    version="${cfg.version}"

    # Ensure Caddy can traverse the state directory
    chmod 0755 "$stateDir"

    current_version=$(cat "$stateDir/.version" 2>/dev/null || echo "")
    if [ "$current_version" != "$version" ]; then
      rm -rf "$stateDir/www"
      cp -rT "${src}/public_html" "$stateDir/www"
      echo "$version" > "$stateDir/.version"
    fi

    mkdir -p "$stateDir/www/app/config"

    # Use example config as base (contains DATABASE_SCHEMA_SQL)
    # and override application settings via sed.
    cp "${src}/public_html/app/config/example.config.php" "$stateDir/www/app/config/config.php"

    db_pass=$(cat "${config.sops.secrets."prologue/db-password".path}")
    csrf=$(cat "${config.sops.secrets."prologue/csrf-secret".path}")

    ${pkgs.gnused}/bin/sed -i \
      -e "s|\$CONFIG_DB_HOST = '.*';|\$CONFIG_DB_HOST = '${cfg.database.host}';|" \
      -e "s|\$CONFIG_DB_USER = '.*';|\$CONFIG_DB_USER = '${cfg.database.user}';|" \
      -e "s|\$CONFIG_DB_PASS = '.*';|\$CONFIG_DB_PASS = '$db_pass';|" \
      -e "s|\$CONFIG_DB_NAME = '.*';|\$CONFIG_DB_NAME = '${cfg.database.name}';|" \
      -e "s|\$CONFIG_APP_URL = '.*';|\$CONFIG_APP_URL = '${cfg.appUrl}';|" \
      -e "s|\$CONFIG_APP_NAME = '.*';|\$CONFIG_APP_NAME = '${cfg.appName}';|" \
      -e "s|\$CONFIG_STORAGE_FILESYSTEM_ROOT = '.*';|\$CONFIG_STORAGE_FILESYSTEM_ROOT = '$stateDir/storage';|" \
      -e "s|\$CONFIG_LOG_DIRECTORY = '.*';|\$CONFIG_LOG_DIRECTORY = '$stateDir/storage/logs';|" \
      -e "s|\$CONFIG_CSRF_SECRET = '.*';|\$CONFIG_CSRF_SECRET = '$csrf';|" \
      "$stateDir/www/app/config/config.php"

    chown prologue:prologue "$stateDir/www/app/config/config.php"
    chmod 0400 "$stateDir/www/app/config/config.php"

    mkdir -p "$stateDir/storage/logs"
    mkdir -p "$stateDir/storage/attachments"

    chown -R prologue:prologue "$stateDir/www" "$stateDir/storage" "$stateDir/.version"
  '';
in
{
  options.services.prologue = {
    enable = lib.mkEnableOption "Prologue communication platform";

    version = lib.mkOption {
      type = lib.types.str;
      default = "0.2.9";
      description = "Prologue version to deploy.";
    };

    srcHash = lib.mkOption {
      type = lib.types.str;
      description = "Hash of the Prologue source archive.";
    };

    appUrl = lib.mkOption {
      type = lib.types.str;
      description = "Public URL of the Prologue instance.";
    };

    appName = lib.mkOption {
      type = lib.types.str;
      default = "Prologue";
      description = "Display name for the Prologue instance.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/prologue";
      description = "Directory for Prologue state (www, storage, config).";
    };

    database = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "MySQL database host.";
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "prologue";
        description = "MySQL database name.";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "prologue";
        description = "MySQL database user.";
      };
    };

    phpfpmPool = lib.mkOption {
      type = lib.types.str;
      default = "prologue";
      description = "PHP-FPM pool name.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.phpfpm.pools.${cfg.phpfpmPool} = {
      user = "prologue";
      group = "prologue";
      phpPackage = phpPackage;

      settings = {
        "listen.owner" = config.services.caddy.user;
        "listen.group" = config.services.caddy.group;
        "pm" = "dynamic";
        "pm.max_children" = 8;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 4;
      };

      phpOptions = ''
        upload_max_filesize = 512M
        post_max_size = 512M
        error_reporting = E_ALL
        log_errors = On
        error_log = ${cfg.stateDir}/storage/logs/php-error.log
      '';
    };

    systemd.services."phpfpm-${cfg.phpfpmPool}" = {
      serviceConfig.ExecStartPre = [ setupScript ];
    };

    users.users.prologue = {
      isSystemUser = true;
      group = "prologue";
      home = cfg.stateDir;
      createHome = true;
    };
    users.groups.prologue = { };
  };
}
