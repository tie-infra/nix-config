{ self, ... }:
{
  imports = [
    self.nixosModules.base-system
    self.nixosModules.erase-your-darlings
    self.nixosModules.trust-admins
  ];

  system.stateVersion = "23.05";

  time.timeZone = "Europe/Moscow";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    initrd.availableKernelModules = [ "ahci" ];
  };

  eraseYourDarlings =
    let disk = "HP_SSD_S750_512GB_HASA33140201321";
    in {
      bootDisk = "/dev/disk/by-id/ata-${disk}-part1";
      rootDisk = "/dev/disk/by-id/ata-${disk}-part2";
    };

  networking = {
    hostName = "akane";
    firewall = {
      allowedTCPPorts = [
        # Netdata
        19999
      ];
    };
  };

  services = {
    fstrim.enable = true;
    netdata.enable = true;
  };
}
