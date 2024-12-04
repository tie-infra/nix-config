{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/all-hardware.nix") ];

  system.stateVersion = lib.trivial.release;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  profiles.btrfs-erase-your-darlings = {
    enable = true;
    bootDisk = "/dev/disk/by-partlabel/efi";
    rootDisk = "/dev/disk/by-partlabel/nix";
  };

  networking = {
    hostName = "bootstrap";
    useDHCP = true;
  };
}
