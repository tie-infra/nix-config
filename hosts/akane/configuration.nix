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

  environment.machineInfo = {
    chassis = "server";
    location = "Ivan’s homelab";
    hardwareVendor = "Qotom";
    hardwareModel = "Q1076GE";
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

  systemd.network.networks."10-wan" = {
    matchConfig = {
      Name = "enp2s0";
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
  };
}
