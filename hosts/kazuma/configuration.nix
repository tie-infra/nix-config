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

  nixpkgs.hostPlatform.system = "x86_64-linux";

  system.stateVersion = "22.11";
  networking.hostName = "kazuma";
  time.timeZone = "Europe/Moscow";

  hardware.enableRedistributableFirmware = true;
  boot.initrd.availableKernelModules = [ "nvme" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  zramSwap.enable = true;
  eraseYourDarlings =
    let disk = "SPCC_M.2_PCIe_SSD_27FF070C189700120672";
    in {
      bootDisk = "/dev/disk/by-id/nvme-${disk}-part1";
      rootDisk = "/dev/disk/by-id/nvme-${disk}-part2";
    };

  environment.systemPackages = [ pkgs.rcon ];

  services = {
    fstrim.enable = true;

    btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/" ];
    };

    netdata.enable = true;

    pufferpanel = {
      enable = true;
      extraPackages = [ pkgs.jre8 pkgs.eco-server ];
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

  networking.firewall = {
    allowedUDPPorts = [ 3000 ];
    allowedTCPPorts = [ 3001 8080 5657 19999 25565 25569 ];
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
