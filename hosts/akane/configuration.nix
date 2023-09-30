{ lib, ... }: {
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

  eraseYourDarlings = {
    bootDisk = "/dev/disk/by-uuid/7F67-589D";
    rootDisk = "/dev/disk/by-uuid/5b169687-13c2-4357-9cfc-d7ecba357db0";
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

  systemd.network =
    let
      wanInterfaces = "enp2s0";
      lanInterfaces = map (i: "enp${toString i}s0") (lib.range 3 9);
      bridgeInterface = "br0";
    in
    {
      networks = {
        "10-wan" = {
          matchConfig = {
            Name = wanInterfaces;
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

        "20-lan" = {
          matchConfig = {
            Name = bridgeInterface;
          };
          networkConfig = {
            # This is just a dummy non-global address to test configuration.
            Address = "192.168.10.1/24";
            ConfigureWithoutCarrier = true;

            # We are the main router on the local network. Do not accept RAs
            # from other routers.
            IPv6AcceptRA = false;
          };
          linkConfig = {
            RequiredForOnline = "no-carrier:routable";
          };
        };

        "30-lan" = {
          matchConfig = {
            Name = lanInterfaces;
          };
          networkConfig = {
            Bridge = bridgeInterface;
            ConfigureWithoutCarrier = true;
          };
          linkConfig = {
            RequiredForOnline = "no-carrier:enslaved";
          };
        };
      };

      netdevs."20-lan" = {
        netdevConfig = {
          Name = bridgeInterface;
          Kind = "bridge";
        };
      };
    };

  services = {
    fstrim.enable = true;
    netdata.enable = true;
  };
}
