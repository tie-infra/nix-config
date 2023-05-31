{ self, ... }:
{ lib, config, pkgs, modulesPath, ... }: {
  imports = [
    self.nixosModules.base-system
    self.nixosModules.erase-your-darlings
    self.nixosModules.trust-admins
  ];

  system.stateVersion = "23.05";

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "ru_RU.UTF-8";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    initrd.availableKernelModules = [ "mpt3sas" "i7core_edac" ];
  };

  eraseYourDarlings =
    let disk = "0x5000c50047d27eab";
    in {
      bootDisk = "/dev/disk/by-id/wwn-${disk}-part1";
      rootDisk = "/dev/disk/by-id/wwn-${disk}-part2";
    };

  networking = {
    hostName = "brim";
    useNetworkd = true;
    useDHCP = false;
    firewall = {
      allowedTCPPorts = [ 19999 ];
    };
  };

  systemd.network.networks."10-wan" = {
    matchConfig = {
      Name = "enp3s0f0";
    };
    networkConfig = {
      Address = [ "185.148.38.208/26" ];
      Gateway = [ "185.148.38.193" ];
      DNS = [ "93.95.97.2" "93.95.100.20" ];
    };
    linkConfig = {
      RequiredForOnline = "routable";
    };
  };

  services.netdata.enable = true;
}
