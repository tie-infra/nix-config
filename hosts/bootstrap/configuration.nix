{ self, ... }:
{ lib, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/all-hardware.nix")
    self.nixosModules.nix-flakes
    self.nixosModules.erase-your-darlings
    self.nixosModules.trust-admins
  ];

  system.stateVersion = lib.trivial.release;
  networking.hostName = "bootstrap";
  time.timeZone = "Europe/Moscow";

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    extraConfig = ''
      LoginGraceTime 15s
      RekeyLimit default 30m
    '';
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

  eraseYourDarlings = {
    bootDisk = "/dev/disk/by-partlabel/efi";
    rootDisk = "/dev/disk/by-partlabel/nix";
  };
}
