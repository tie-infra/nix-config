{ ... }:
{
  system.stateVersion = "24.05";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    initrd.availableKernelModules = [ "nvme" ];
  };

  environment.machineInfo = {
    chassis = "server";
    location = "Falkenstein";
  };

  profiles.btrfs-erase-your-darlings = {
    enable = true;
    bootDisk = "/dev/disk/by-uuid/2EBA-AC04";
    rootDisk = "/dev/disk/by-uuid/84b3349c-3c87-4d95-b4de-1c1a646fce09";
  };

  networking.hostName = "falcon";

  systemd.network = {
    networks = {
      "10-wan" = {
        matchConfig = {
          Name = "enp9s0";
        };
        addresses = [
          {
            addressConfig = {
              Address = "2a01:4f8:222:1618::1/64";
              AddPrefixRoute = false;
              DuplicateAddressDetection = "none";
              ManageTemporaryAddress = true;
            };
          }
          {
            addressConfig = {
              Address = "213.133.111.103/27";
              AddPrefixRoute = false;
            };
          }
        ];
        routes = [
          {
            routeConfig = {
              Gateway = "fe80::1";
              GatewayOnLink = true;
            };
          }
          {
            routeConfig = {
              Gateway = "213.133.111.97";
              GatewayOnLink = true;
            };
          }
        ];
        networkConfig = {
          IPv6AcceptRA = false;
          IPv6PrivacyExtensions = true;
          DNS = [
            "2606:4700:4700::1111"
            "2606:4700:4700::1001"
            "1.1.1.1"
            "1.0.0.1"
          ];
        };
        linkConfig = {
          RequiredForOnline = "routable";
        };
      };
    };
  };
}
