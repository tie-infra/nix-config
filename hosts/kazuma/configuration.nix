{ self, inputs, ... }:
{ config, pkgs, ... }: {
  imports = [
    self.nixosModules.erase-your-darlings
    self.nixosModules.nix-flakes
    self.nixosModules.trust-admins
    inputs.agenix.nixosModules.default
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

  environment.systemPackages = with pkgs; [
    file
    htop
    btop
  ];

  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
    dockerCompat = true;
  };

  services = {
    openssh = {
      enable = true;
      startWhenNeeded = true;
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
      extraConfig = ''
        LoginGraceTime 15s
        RekeyLimit default 30m
      '';
    };
    fstrim.enable = true;
    netdata.enable = true;
    pufferpanel = {
      enable = true;
      openFirewall = true;
      extraPackages = [ pkgs.jre8 ];
      extraGroups = [ "podman" ];
      panel.enable = false;
      daemon.auth = {
        url = "https://panel.brim.ml/oauth2/token";
        clientId = ".node_2";
        clientSecretFile = config.age.secrets.pufferpanel-client-secret.path;
      };
      environment = {
        PUFFER_TOKEN_PUBLIC = "https://panel.brim.ml/auth/publickey";
        PUFFER_DAEMON_CONSOLE_BUFFER = "1000";
      };
    };
  };

  users = {
    mutableUsers = false;
    users.nixos = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = with self.lib.sshKeys;
        github-actions ++ tie;
    };
  };

  networking.firewall = {
    allowedUDPPorts = [ 3000 ];
    allowedTCPPorts = [ 3001 19999 25565 25569 ];
    logRefusedConnections = false;
  };

  age.secrets.pufferpanel-client-secret = {
    file = ./pufferpanel-client-secret.age;
  };
}
