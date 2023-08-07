{ self, inputs, ... }:
{ lib, pkgs, config, ... }: {
  imports = [
    self.nixosModules.base-system
    self.nixosModules.erase-your-darlings
    self.nixosModules.trust-admins
    inputs.sops-nix.nixosModules.default
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [
      "eco-server"
    ];

  system.stateVersion = "22.11";

  time.timeZone = "Europe/Moscow";

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

  eraseYourDarlings = {
    bootDisk = "/dev/disk/by-uuid/1628-65F3";
    rootDisk = "/dev/disk/by-uuid/5104f49c-ff08-49dc-96e4-8fbe00702f0a";
  };

  networking = {
    hostName = "kazuma";
    firewall = {
      allowedUDPPorts = [ 3000 ];
      allowedTCPPorts = [ 3001 8080 5657 19999 25565 25569 ];
    };
  };

  systemd.network.networks."10-wan" = {
    matchConfig = {
      Name = "enp34s0";
    };
    networkConfig = {
      DHCP = "yes";
      IPv6PrivacyExtensions = "kernel";
    };
    dhcpV6Config = {
      UseDelegatedPrefix = false;
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
      extraPackages = [
        pkgs.jre8
        pkgs.eco-server
      ];
      environment = {
        PUFFER_WEB_HOST = ":8080";
        PUFFER_DAEMON_SFTP_HOST = ":5657";
        PUFFER_PANEL_ENABLE = "false";
        PUFFER_TOKEN_PUBLIC = "https://panel.brim.ml/auth/publickey"; # deprecated in v3
        PUFFER_DAEMON_AUTH_URL = "https://panel.brim.ml/oauth2/token";
        PUFFER_DAEMON_AUTH_CLIENTID = ".node_2";
        # PUFFER_DAEMON_AUTH_CLIENTSECRET is set via environmentFile
        PUFFER_DAEMON_CONSOLE_BUFFER = "1000";
      };
      environmentFile = config.sops.secrets."pufferpanel/env".path;
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      "pufferpanel/env" = {
        restartUnits = [ "pufferpanel.service" ];
      };
    };
  };
}
