{ pkgs, config, ... }:
{
  system.stateVersion = "23.11";

  i18n.defaultLocale = "ru_RU.UTF-8";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    initrd.availableKernelModules = [
      "mpt3sas"
      "i7core_edac"
    ];
  };

  environment.machineInfo = {
    chassis = "server";
    location = "mtw.ru colocation";
  };

  profiles.btrfs-erase-your-darlings = {
    enable = true;
    bootDisk = "/dev/disk/by-uuid/2FAC-A633";
    rootDisk = "/dev/disk/by-uuid/96448376-c96b-4fa0-adcb-65dee46427c0";
  };

  networking = {
    hostName = "brim";
    firewall = {
      allowedTCPPorts = [
        # Caddy HTTP/1 and HTTP/2
        443
      ];
      allowedTCPPortRanges = [
        # Brim Minecraft
        {
          from = 25500;
          to = 25599;
        }
        # Shared Minecraft (for Tie)
        {
          from = 22500;
          to = 22599;
        }
      ];
      allowedUDPPorts = [
        # Caddy HTTP/3
        443
        # Palworld
        8211
        # Satisfactory
        7777
        15000
        15777
        # Minecraft SimpleVoiceChat
        24454
        24455
      ];
    };
  };

  systemd.network.networks."10-wan" = {
    matchConfig = {
      Name = "enp3s0f0";
    };
    networkConfig = {
      Address = [
        "185.148.38.208/26"
        "2a00:f440:0:614::11/64"
        "2a00:f440:0:614::12/64"
        "2a00:f440:0:614::13/64"
        "2a00:f440:0:614::14/64"
        "2a00:f440:0:614::15/64"
        "2a00:f440:0:614::16/64"
        "2a00:f440:0:614::17/64"
        "2a00:f440:0:614::18/64"
        "2a00:f440:0:614::19/64"
        "2a00:f440:0:614::1a/64"
        "2a00:f440:0:614::1b/64"
        "2a00:f440:0:614::1c/64"
        "2a00:f440:0:614::1d/64"
        "2a00:f440:0:614::1e/64"
        "2a00:f440:0:614::1f/64"
      ];
      Gateway = [
        "185.148.38.193"
        "2a00:f440:0:614::1"
      ];
      DNS = [
        "93.95.97.2"
        "93.95.100.20"
      ];
    };
    linkConfig = {
      RequiredForOnline = "routable";
    };
  };

  services = {
    netdata.enable = true;

    syncthing = {
      enable = true;
      guiAddress = ":8384";
      overrideFolders = false;
      overrideDevices = false;
      openDefaultPorts = true;
    };

    mysql = {
      enable = true;
      package = pkgs.mariadb_1011;
    };

    redis.servers.outline = {
      enable = true;
      bind = "::1 127.0.0.1";
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
    };

    caddy = {
      enable = true;
      adapter = "caddyfile";
      configFile = ./Caddyfile;
    };

    pufferpanel = {
      enable = true;
      extraPackages = with pkgs; [
        satisfactory-server
        palworld-server
        javaWrappers.java8
        javaWrappers.java17
        javaWrappers.java21
      ];

      environment = {
        PUFFER_WEB_HOST = ":8080";
        PUFFER_PANEL_REGISTRATIONENABLED = "false";
        PUFFER_DAEMON_SFTP_HOST = ":5657";
        PUFFER_DAEMON_CONSOLE_BUFFER = "1000";
      };
    };

    minio = {
      enable = true;
      environment = {
        MINIO_SERVER_URL = "https://s3.brim.su";
        MINIO_ROOT_USER = "minio";
      };
      environmentFile = config.sops.templates."minio.env".path;
    };

    mcactivity = {
      enable = true;
      settings = {
        config = {
          bot_token = "\${MCACTIVITY_BOT_TOKEN}";
          server_ip = "play1.brimworld.online";
          server_port = "25511";
          activity_format = "BrimWorld: {online}/{max}";
          players_format = "Игроков: {online}/{max}";
          status_online =
            "Сервер в сети "
            +
              # Honey Pot U+1F36F
              builtins.fromJSON ''"\uD83C\uDF6F"'';
          status_offline =
            "Сервер не в сети "
            +
              # Broken Heart U+1F494
              builtins.fromJSON ''"\uD83D\uDC94"'';
        };
        channels = {
          enable_channels = true;
          channel_1_id = "942439402272075786";
          channel_2_id = "942439439483940984";
        };
      };
    };
  };

  # TODO: refactor into separate module?
  systemd.services.outline = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    environment = {
      NODE_ENV = "production";

      URL = "https://wiki.brimworld.online";
      PORT = "3000";

      DATABASE_URL = "postgresql://localhost/outline?user=outline&host=/run/postgresql&sslmode=disable";
      REDIS_URL = "unix://${config.services.redis.servers.outline.unixSocket}";

      DISCORD_SERVER_ID = "925681822766092319"; # BrimWorld
      DISCORD_SERVER_ROLES = "925695895880761345,1281827267634401341"; # Admin, Wiki editor
      DISCORD_CLIENT_ID = "1279604766476861451";
      # DISCORD_CLIENT_SECRET is set from EnvironmentFile.

      FILE_STORAGE = "s3";
      AWS_ACCESS_KEY_ID = "y2gCQlb66nIzJLthers4";
      AWS_REGION = "eu-west-1";
      # AWS_SECRET_ACCESS_KEY is set from EnvironmentFile.
      AWS_S3_UPLOAD_BUCKET_URL = "https://s3.brim.su";
      AWS_S3_UPLOAD_BUCKET_NAME = "outline";
      AWS_S3_FORCE_PATH_STYLE = "1";

      FILE_STORAGE_UPLOAD_MAX_SIZE = "100000000"; # 100 MB
    };

    restartTriggers = [ config.sops.templates."outline.env".file ];

    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.outline}/bin/outline-server";
      WorkingDirectory = "${pkgs.outline}/share/outline";

      EnvironmentFile = config.sops.templates."outline.env".path;

      Restart = "always";

      DynamicUser = true;
      SupplementaryGroups = [
        config.users.groups.postgres.name
        config.services.redis.servers.outline.user
      ];

      UMask = "0007";

      StateDirectory = "outline";
      StateDirectoryMode = "0750";
      RuntimeDirectory = "outline";
      RuntimeDirectoryMode = "0750";
    };
  };

  systemd.services.mcactivity.serviceConfig = {
    EnvironmentFile = config.sops.templates."mcactivity.env".path;
    IPAddressAllow = [ "any" ];
    IPAddressDeny = [
      "localhost"
      "link-local"
      "multicast"
    ];
  };

  systemd.services.caddy = {
    environment = {
      TLS_CERTIFICATE_PATH_FOR_BRIM_SU = ./certs/brim-su.pem;
      TLS_CERTIFICATE_PATH_FOR_BRIMWORLD_ONLINE = ./certs/brimworld-online.pem;
    };
    serviceConfig.LoadCredential = map (
      name: name + ":" + config.sops.secrets."caddy/${name}".path
    ) config.passthru.caddySecrets;
  };
}
