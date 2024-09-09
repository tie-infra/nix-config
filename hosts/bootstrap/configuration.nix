{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/all-hardware.nix") ];

  system.stateVersion = lib.trivial.release;

  time.timeZone = "Europe/Moscow";

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  eraseYourDarlings = {
    bootDisk = "/dev/disk/by-partlabel/efi";
    rootDisk = "/dev/disk/by-partlabel/nix";
  };

  networking = {
    hostName = "bootstrap";
    useDHCP = true;
  };
}
