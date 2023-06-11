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
      "satisfactory-server"
      "steamworks-sdk-redist"
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

  eraseYourDarlings =
    let disk = "SPCC_M.2_PCIe_SSD_27FF070C189700120672";
    in {
      bootDisk = "/dev/disk/by-id/nvme-${disk}-part1";
      rootDisk = "/dev/disk/by-id/nvme-${disk}-part2";
    };

  networking = {
    hostName = "kazuma";
    firewall = {
      allowedUDPPorts = [ 3000 7777 15000 15777 ];
      allowedTCPPorts = [ 3001 8080 5657 19999 25565 25569 ];
    };
  };

  services = {
    fstrim.enable = true;

    btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/" ];
    };

    netdata.enable = true;

    pufferpanel = {
      enable = true;
      extraPackages = [
        pkgs.jre8
        pkgs.eco-server
        pkgs.satisfactory-server
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
