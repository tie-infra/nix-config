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

    initrd.availableKernelModules = [ "virtio" ];
  };

  eraseYourDarlings = {
    bootDisk = "/dev/vda1";
    rootDisk = "/dev/vda2";
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
    firewall = {
      enable = false;
      allowedTCPPorts = [
        # Netdata
        19999
      ];
      allowedUDPPorts = [
        # WireGuard
        51820
      ];
    };
  };

  # TODO: config.sops.secrets."wireguard/pk.txt".path;
  # https://kalnytskyi.com/posts/setup-wireguard-systemd-networkd
  # https://elou.world/en/tutorial/wireguard

  systemd.network = let prefix48 = "2a12:5940:7226"; in {
    networks = {
      "10-wan" = {
        matchConfig = {
          Name = "ens3";
        };
        networkConfig = {
          Address = [
            "${prefix48}::face/128"
            "79.137.248.232/32"
          ];
          DNS = [
            "2606:4700:4700::1111"
            "2606:4700:4700::1001"
            "1.1.1.1"
            "1.0.0.1"
          ];

          IPv6AcceptRA = false;
        };
        linkConfig = {
          RequiredForOnline = "routable";
        };
        routes = map
          (address: {
            routeConfig = {
              Gateway = address;
              GatewayOnLink = true;
            };
          })
          [
            "2a12:5940:7226::1"
            "10.0.0.1"
          ];
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
