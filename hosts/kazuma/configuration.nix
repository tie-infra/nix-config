{ pkgs, config, ... }:
{
  system.stateVersion = "23.11";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    initrd.availableKernelModules = [ "nvme" ];
  };

  environment.machineInfo = {
    chassis = "server";
    location = "Ivan’s homelab";
  };

  profiles.btrfs-erase-your-darlings = {
    enable = true;
    bootDisk = "/dev/disk/by-uuid/1628-65F3";
    rootDisk = "/dev/disk/by-uuid/5104f49c-ff08-49dc-96e4-8fbe00702f0a";
  };

  networking = {
    hostName = "kazuma";
    firewall = {
      allowedUDPPorts = [
        3000
        7777 # satisfactory-server
        28015 # rust-server (game)
        28016 # rust-server (query)
      ];
      allowedTCPPorts = [
        3001
        8080
        5657
        7777 # satisfactory-server
        8888 # satisfactory-server
        19999
        28015 # rust-server (rcon)
        28082 # rust-server (plus)
      ];
      allowedTCPPortRanges = [
        # Minecraft
        {
          from = 25500;
          to = 25599;
        }
      ];
    };
  };

  systemd.network.networks."10-wan" = {
    matchConfig = {
      Name = "enp6s0";
    };
    networkConfig = {
      DHCP = true;
    };
    linkConfig = {
      RequiredForOnline = "routable";
    };
  };

  services = {
    fstrim.enable = true;

    netdata.enable = true;

    pufferpanel = {
      enable = true;
      extraPackages = with pkgs; [
        rust-server.oxide
        eco-server
        satisfactory-server
        javaWrappers.java8
        javaWrappers.java17
        javaWrappers.java21
      ];
      environment = {
        PUFFER_WEB_HOST = ":8080";
        PUFFER_DAEMON_SFTP_HOST = ":5657";
        PUFFER_PANEL_ENABLE = "false";
        PUFFER_TOKEN_PUBLIC = "https://panel.brim.su/auth/publickey"; # deprecated in v3
        PUFFER_DAEMON_AUTH_URL = "https://panel.brim.su/oauth2/token";
        PUFFER_DAEMON_AUTH_CLIENTID = ".node_2";
        # PUFFER_DAEMON_AUTH_CLIENTSECRET is set via environmentFile
        PUFFER_DAEMON_CONSOLE_BUFFER = "1000";
      };
      environmentFile = config.sops.secrets."pufferpanel/env".path;
    };
  };

  sops.secrets = {
    "pufferpanel/env" = {
      restartUnits = [ "pufferpanel.service" ];
      sopsFile = ../../secrets/kazuma.sops.yaml;
    };
  };
}
