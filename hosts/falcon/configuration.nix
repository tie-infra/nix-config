{ config, ... }:
{
  system.stateVersion = "24.05";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    kernelParams = [ "nomodeset" ]; # for KVM Console

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
  networking = {
    firewall = {
      enable = true;
      logReversePathDrops = true;
      allowedUDPPorts = [ 51820 ];
      allowedTCPPorts = [ 19999 ];
    };
    # systemd-networkd masquerading is not flexible enough for our setup.
    # See https://github.com/systemd/systemd/issues/8040
    nat = {
      enable = true;
      externalInterface = "enp9s0";
      internalIPs = [ "172.16.0.0/12" ];
    };
    tcpmssClamping = {
      enable = true;
    };
  };

  systemd.network.config = {
    networkConfig = {
      IPv4Forwarding = true;
      IPv6Forwarding = true;
    };
  };

  # Available subnets:
  # • 2a01:4f8:222:fe00::/56
  # • 2a01:4f8:222:1618::/64
  # • 213.133.111.103/32
  # • 172.16.0.0/12
  systemd.network = {
    networks = {
      "10-wan" = {
        matchConfig = {
          Name = "enp9s0";
        };
        addresses = [
          {
            Address = "2a01:4f8:222:1618::1/64";
            AddPrefixRoute = false;
            DuplicateAddressDetection = "none";
            ManageTemporaryAddress = true;
          }
          {
            Address = "213.133.111.103/27";
            AddPrefixRoute = false;
          }
        ];
        routes = [
          {
            Gateway = "fe80::1";
            GatewayOnLink = true;
          }
          {
            Gateway = "213.133.111.97";
            GatewayOnLink = true;
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
      "20-wg" = {
        matchConfig = {
          Name = "wg-lan";
        };
        linkConfig = {
          RequiredForOnline = "carrier:routable";
        };
      };
    };
    netdevs = {
      "10-wg" = {
        netdevConfig = {
          Name = "wg-lan";
          Kind = "wireguard";
        };
        wireguardConfig = {
          ListenPort = 51820;
          PrivateKeyFile = config.sops.secrets."wireguard/pk.txt".path;
          H1 = 224412;
          H2 = 52344123;
          H3 = 6713390;
          H4 = 2537922;
        };
        wireguardPeers = [
          # akane
          {
            AdvancedSecurity = true;
            AllowedIPs = [
              "2a01:4f8:222:fee0::/60"
              # NB 28d = 00011100b = 1Ch, damn IPv4 subnets are not easy.
              # That said, we can use 28–31 for a /16 subnet.
              "172.28.0.0/14"
            ];
            RouteTable = "main";
            PublicKey = "gvAPp/g475vG9Jpj9b4rdPKPwhIKvuxynuw8EffMrGk=";
            PresharedKeyFile = config.sops.secrets."wireguard/psk.txt".path;
          }
          # eerie (TODO: remove after rolling out akane)
          {
            AdvancedSecurity = true;
            AllowedIPs = [
              "2a01:4f8:222:fe00::3/128"
              "172.16.0.3/32"
            ];
            RouteTable = "main";
            PublicKey = "UaXdcPYo2GiqdXgaxlkGpeKQKO7casrRR9eJCZs5RVs=";
            PresharedKeyFile = config.sops.secrets."wireguard/psk.txt".path;
          }
        ];
      };
    };
  };

  services = {
    fstrim.enable = true;
    netdata.enable = true;
  };

  systemd.services.systemd-networkd = {
    serviceConfig = {
      SupplementaryGroups = [ config.users.groups.keys.name ];
    };
  };

  sops.secrets = {
    "wireguard/pk.txt" = {
      mode = "0440";
      group = config.users.groups.systemd-network.name;
      reloadUnits = [ config.systemd.services.systemd-networkd.name ];
      sopsFile = ../../secrets/wireguard-pk-falcon.sops.yaml;
    };
    "wireguard/psk.txt" = {
      mode = "0440";
      group = config.users.groups.systemd-network.name;
      reloadUnits = [ config.systemd.services.systemd-networkd.name ];
      sopsFile = ../../secrets/wireguard-psk.sops.yaml;
    };
  };
}
