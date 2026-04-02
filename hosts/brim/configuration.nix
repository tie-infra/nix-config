{
  config,
  lib,
  pkgs,
  ...
}:
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
    bootDisk = "/dev/disk/by-uuid/9F30-7212";
    rootDisk = "/dev/disk/by-uuid/96448376-c96b-4fa0-adcb-65dee46427c0";
  };

  networking = {
    hostName = "brim";
    firewall = {
      allowedTCPPorts = [
        # PufferPanel SFTP
        5657
      ];
      allowedTCPPortRanges = [
        # Minecraft
        {
          from = 25500;
          to = 25599;
        }
      ];
      allowedUDPPorts = [
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

    outline.enable = true;

    pufferpanel = {
      enable = true;
      extraPackages = with pkgs; [
        javaWrappers.java8
        javaWrappers.java17
        javaWrappers.java21
        javaWrappers.java25
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

    prologue = {
      enable = true;
      appUrl = "https://chat.brim.su";
      srcHash = "sha256-H46m38tWX/+pRU5Q9LG8osHXzXeeYMj4QNF7GsYekrE=";
    };

    # Outgoing-only mail server for Prologue notifications.
    postfix = {
      enable = true;
      # Submission on port 587 for Prologue (connects to brim.su:587).
      # Restricted to localhost via mynetworks + permit_mynetworks.
      enableSubmission = true;
      submissionOptions = {
        smtpd_tls_security_level = "encrypt";
        smtpd_client_restrictions = "permit_mynetworks,reject";
        milter_macro_daemon_name = "ORIGINATING";
      };
      settings.main = {
        myhostname = "brim.su";
        mydomain = "brim.su";
        myorigin = "brim.su";
        mydestination = ""; # no local delivery
        # Listen on all interfaces (submission needs public IP for TLS CN match).
        # Port 25 blocked by firewall. Submission 587 restricted to localhost.
        inet_interfaces = "all";
        mynetworks = [ "127.0.0.0/8" "[::1]/128" ];
        # TLS for outgoing
        smtp_tls_security_level = "may";
        smtp_tls_CApath = "/etc/ssl/certs";
        # TLS cert from Caddy ACME
        smtpd_tls_cert_file = "/var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/brim.su/brim.su.crt";
        smtpd_tls_key_file = "/var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/brim.su/brim.su.key";
        smtpd_tls_security_level = "may";
        # DKIM milter
        smtpd_milters = "unix:/run/opendkim/opendkim.sock";
        non_smtpd_milters = "unix:/run/opendkim/opendkim.sock";
        milter_default_action = "accept";
      };
    };

    opendkim = {
      enable = true;
      domains = "brim.su";
      selector = "mail";
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

  services.nfqws = {
    enable = true;
    instances."" = {
      settings.qnum = 200;
      profiles."".settings = {
        dpi-desync = "fakedsplit";
        dpi-desync-fooling = "datanoack";
        dpi-desync-split-pos = 1;
        hostlist = map pkgs.copyPathToStore [
          ../../zapret/discord-domains.txt
        ];
        hostlist-domains = lib.concatStringsSep "," [
          "cloudflare-ech.com" # TLS ECH
          "repo.nickuc.com"
        ];
      };
    };
  };

  # https://github.com/bol-van/zapret?tab=readme-ov-file#nftables-для-nfqws
  networking.nftables.tables.zapret = {
    family = "inet";
    content = ''
      chain pre {
        type filter hook prerouting priority filter;
        tcp sport {80,443} ct reply packets 1-3 queue num 200 bypass
      }
      chain post {
        type filter hook postrouting priority mangle;
        meta mark and 0x40000000 == 0 tcp dport {80,443} ct original packets 1-6 queue num 200 bypass
        meta mark and 0x40000000 == 0 udp dport 443 ct original packets 1-6 queue num 200 bypass
      }
    '';
  };

  boot.kernel.sysctl."net.netfilter.nf_conntrack_tcp_be_liberal" = true;

  systemd.services.outline = {
    environment = {
      NODE_ENV = "production";

      URL = "https://brimworld.online";
      CDN_URL = "https://brimworld.online";
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
      EnvironmentFile = config.sops.templates."outline.env".path;
      SupplementaryGroups = [
        config.users.groups.postgres.name
        config.services.redis.servers.outline.user
      ];
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

  # Allow Postfix to access OpenDKIM socket and Caddy TLS certs.
  users.users.${config.services.postfix.user}.extraGroups = [
    config.services.opendkim.group
    config.services.caddy.group
  ];

  sops.templates."minio.env".content = ''
    MINIO_ROOT_PASSWORD=${config.sops.placeholder."minio/root-password"}
  '';

  sops.templates."mcactivity.env".content = ''
    MCACTIVITY_BOT_TOKEN=${config.sops.placeholder."discord/brimworld-bot-token"}
  '';

  sops.templates."outline.env".content = ''
    SECRET_KEY=${config.sops.placeholder."outline/secret-key"}
    UTILS_SECRET=${config.sops.placeholder."outline/utils-secret"}
    DISCORD_CLIENT_SECRET=${config.sops.placeholder."outline/discord-client-secret"}
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."outline/s3-secret-access-key"}
  '';

  sops.secrets = {
    "outline/secret-key" = {
      restartUnits = [ "outline.service" ];
      sopsFile = ../../secrets/brim.sops.yaml;
    };
    "outline/utils-secret" = {
      restartUnits = [ "outline.service" ];
      sopsFile = ../../secrets/brim.sops.yaml;
    };
    "outline/discord-client-secret" = {
      restartUnits = [ "outline.service" ];
      sopsFile = ../../secrets/brim.sops.yaml;
    };
    "outline/s3-secret-access-key" = {
      restartUnits = [ "outline.service" ];
      sopsFile = ../../secrets/brim.sops.yaml;
    };
    "discord/brimworld-bot-token" = {
      restartUnits = [ "mcactivity.service" ];
      sopsFile = ../../secrets/brim.sops.yaml;
    };
    "minio/root-password" = {
      restartUnits = [ "minio.service" ];
      sopsFile = ../../secrets/brim.sops.yaml;
    };
    "prologue/db-password" = {
      restartUnits = [ "phpfpm-prologue.service" ];
      owner = "prologue";
      sopsFile = ../../secrets/brim.sops.yaml;
    };
    "prologue/csrf-secret" = {
      restartUnits = [ "phpfpm-prologue.service" ];
      owner = "prologue";
      sopsFile = ../../secrets/brim.sops.yaml;
    };
  };
}
