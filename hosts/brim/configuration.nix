let
  cloudflareCerts = {
    CF_SERVER_BRIM_CERT_PATH = "brim-cert.pem";
    CF_SERVER_BRIM_KEY_PATH = "brim-key.pem";
    CF_SERVER_BRIMWORLD_ONLINE_CERT_PATH = "brimworld-online-cert.pem";
    CF_SERVER_BRIMWORLD_ONLINE_KEY_PATH = "brimworld-online-key.pem";
    CF_SERVER_BRIMWORLD_RU_CERT_PATH = "brimworld-ru-cert.pem";
    CF_SERVER_BRIMWORLD_RU_KEY_PATH = "brimworld-ru-key.pem";
  };
in
{ lib, pkgs, config, ... }: {
  system.stateVersion = "23.05";

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
        # Minecraft
        25511
        25521
      ];
      allowedUDPPorts = [
        # Caddy HTTP/3
        443
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
      extraPackages = [
        (pkgs.satisfactory-server.overrideAttrs (_: {
          version = "0.8.2.1-5.2.1+259808";
          src = pkgs.fetchSteam {
            appId = "1690800";
            depotId = "1690802";
            manifestId = "6049335616683476102";
            hash = "sha256-mJ7MD5+2rUKTVjHe0FKGkS9/wqIICW/t9f+QZ5gybrQ=";
          };
        }))
        (pkgs.writeShellScriptBin "openjdk-java8" ''
          set -eu
          exec ${lib.getExe pkgs.jre8} "$@"
        '')
        (pkgs.writeShellScriptBin "graalvm-java17" ''
          set -eu
          exec ${lib.getExe pkgs.graalvm17-ce} "$@"
        '')
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
      environment.MINIO_SERVER_URL = "https://s3.brim.su";
      environmentFile = config.sops.secrets."minio/env".path;
    };
  };

  systemd.services.caddy.serviceConfig = {
    LoadCredential = lib.mapAttrsToList
      (_: value: "${value}:${config.sops.secrets."caddy/${value}".path}")
      cloudflareCerts;
    Environment = lib.mapAttrsToList
      (name: value: "${name}=%d/${value}")
      cloudflareCerts;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      "minio/env" = {
        restartUnits = [ "minio.service" ];
      };
    } // lib.mapAttrs'
      (_: value: lib.nameValuePair "caddy/${value}" {
        restartUnits = [ "caddy.service" ];
      })
      cloudflareCerts;
  };
}
