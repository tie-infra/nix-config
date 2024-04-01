{ lib, pkgs, config, ... }: {
  system.stateVersion = "23.11";

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "ru_RU.UTF-8";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    initrd.availableKernelModules = [ "mpt3sas" "i7core_edac" ];
  };

  environment.machineInfo = {
    chassis = "server";
    location = "mtw.ru colocation";
  };

  eraseYourDarlings = {
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
        { from = 25500; to = 25599; },
        # Shared Minecraft (for Tie)
        { from = 22500; to = 22599; }
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
  };

  systemd.services.caddy = {
    environment = {
      TLS_CERTIFICATE_PATH_FOR_BRIM_SU = ./certs/brim-su.pem;
      TLS_CERTIFICATE_PATH_FOR_BRIMWORLD_ONLINE = ./certs/brimworld-online.pem;
    };
    serviceConfig.LoadCredential =
      map
        (name: name + ":" + config.sops.secrets."caddy/${name}".path)
        config.passthru.caddySecrets;
  };
}
