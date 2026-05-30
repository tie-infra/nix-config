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

  pythonEnv = pkgs.python3.withPackages (ps: [ ps.cryptography ]);

  # Setup hook run before php-fpm starts. See ./prologue-setup.py.
  setupScript = ./prologue-setup.py;

  # Configuration consumed by the setup script. Secrets are referenced by path
  # and read at runtime so they never land in the Nix store.
  setupConfig = (pkgs.formats.json { }).generate "prologue-setup.json" {
    inherit (cfg) version stateDir appUrl appName;
    src = "${src}";
    dbHost = cfg.database.host;
    dbUser = cfg.database.user;
    dbName = cfg.database.name;
    dbPasswordFile = config.sops.secrets."prologue/db-password".path;
    csrfSecretFile = config.sops.secrets."prologue/csrf-secret".path;
  };
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
      serviceConfig.ExecStartPre = [ "${pythonEnv}/bin/python3 ${setupScript} ${setupConfig}" ];
    };

    # Ensure Caddy can traverse the state directory.
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 prologue prologue -"
    ];

    users.users.prologue = {
      isSystemUser = true;
      group = "prologue";
      home = cfg.stateDir;
    };
    users.groups.prologue = { };
  };
}
