{ config, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  system.stateVersion = "23.11";

  time.timeZone = "Europe/Moscow";

  boot.loader.grub = {
    enable = true;
    configurationLimit = 10;
    device = "/dev/disk/by-path/virtio-pci-0000:00:07.0";
  };

  eraseYourDarlings = {
    bootDisk = "/dev/disk/by-uuid/2C36-A9EE";
    rootDisk = "/dev/disk/by-uuid/d953273d-8717-4eed-9db8-0e0c16749784";
  };

  environment = {
    machineInfo = {
      location = "Helsinki VDS from aeza.net";
    };

    systemPackages = with pkgs; [
      wireguard-tools
      traceroute
      tcpdump
    ];
  };

  networking = {
    hostName = "helsing";
    firewall.enable = false;
  };

  # TODO: config.sops.secrets."wireguard/pk.txt".path;
  # https://kalnytskyi.com/posts/setup-wireguard-systemd-networkd
  # https://elou.world/en/tutorial/wireguard

  systemd.network =
    let
      prefix48 = "2a12:5940:7226"; # /48 subnet

      addresses = [
        "${prefix48}::face/128"
        "79.137.248.232/24"
      ];

      gateways = [
        "2a12:5940:7226::1"
        "10.0.0.1"
      ];

      dnsServers = [
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
        "1.1.1.1"
        "1.0.0.1"
      ];

      gatewayToRouteConfig = address: {
        routeConfig = {
          Gateway = address;
          GatewayOnLink = true;
        };
      };
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
        "wg-lan" = {
          matchConfig = {
            Name = "wg-lan";
          };
          networkConfig = {
            Address = [
              "172.16.0.1/12"
              "${prefix48}:1000::1/56"
            ];

            IPForward = true;
            IPMasquerade = "ipv4";
          };
          linkConfig = {
            RequiredForOnline = "carrier:routable";
          };
        };
      };
      netdevs.wg-lan = {
        netdevConfig = {
          Name = "wg-lan";
          Kind = "wireguard";
        };
        wireguardConfig = {
          ListenPort = 51820;
          PrivateKeyFile = config.sops.secrets."wireguard/pk.txt".path;
        };
        wireguardPeers = [{
          wireguardPeerConfig = {
            AllowedIPs = [
              "172.16.0.0/12"
              "${prefix48}:1000::/56"
            ];
            PublicKey = "UaXdcPYo2GiqdXgaxlkGpeKQKO7casrRR9eJCZs5RVs=";
            PresharedKeyFile = config.sops.secrets."wireguard/psk.txt".path;
          };
        }];
      };
    };

  services = {
    netdata.enable = true;
    qemuGuest.enable = true;

    # See https://superuser.com/a/1728017
    ndppd = {
      enable = true;
      proxies."ens3".rules."2a12:5940:7226:1000::/56".method = "static";
    };
  };

  systemd.services.systemd-networkd = {
    serviceConfig = {
      SupplementaryGroups = [ config.users.groups.keys.name ];
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      "wireguard/pk.txt" = {
        mode = "0440";
        group = config.users.groups.systemd-network.name;
        reloadUnits = [ "systemd-networkd.service" ];
      };
      "wireguard/psk.txt" = {
        mode = "0440";
        group = config.users.groups.systemd-network.name;
        reloadUnits = [ "systemd-networkd.service" ];
      };
    };
  };
}
