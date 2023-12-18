{ config, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  system.stateVersion = "23.11";

  time.timeZone = "Europe/Moscow";

  boot = {
    loader.grub = {
      enable = true;
      configurationLimit = 10;
      device = "/dev/vda";
    };
  };

  eraseYourDarlings = {
    bootDisk = "/dev/vda1";
    rootDisk = "/dev/vda2";
  };

  environment = {
    machineInfo = {
      location = "Amsterdam VPS from 4vps.su";
    };
  };

  networking = {
    hostName = "hikari";
    firewall.enable = false;
  };

  systemd.network =
    let
      address4 = "62.133.61.102";
      prefix6 = "2a00:b703:fff1:88"; # /64

      addresses = [
        "${prefix6}::1/48" # /64 subnet
        "${address4}/32"
      ];

      gateways = [
        "2a00:b703:fff1::1"
        "62.133.61.1"
      ];

      dnsServers = [
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
        "1.1.1.1"
        "1.0.0.1"
      ];

      gatewayToRouteConfig = (address: {
        routeConfig = {
          Gateway = address;
          GatewayOnLink = true;
        };
      });
    in
    {
      networks = {
        "10-wan" = {
          matchConfig = {
            Name = "ens3";
          };
          networkConfig = {
            Address = addresses;
            DNS = dnsServers;
            IPv6AcceptRA = false;
          };
          linkConfig = {
            RequiredForOnline = "routable";
          };
          routes = map gatewayToRouteConfig gateways;
        };
      };
    };

  services = {
    netdata.enable = true;
    qemuGuest.enable = true;
  };
}
