{ config, ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

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
      externalInterface = "ens3";
      internalIPs = [ "172.16.0.0/12" ];
    };
    nftables = {
      enable = true;
    };
  };

  systemd.network = {
    networks = {
      "10-wan" = {
        matchConfig = {
          Name = "ens3";
        };
        addresses = [
          {
            addressConfig = {
              Address = "2a12:5940:7226::2/64";
              AddPrefixRoute = false;
              DuplicateAddressDetection = "none";
              ManageTemporaryAddress = true;
            };
          }
          {
            addressConfig = {
              Address = "79.137.248.232/32";
              AddPrefixRoute = false;
            };
          }
        ];
        routes = [
          {
            routeConfig = {
              Gateway = "fe80::fc54:ff:fe17:c905";
              GatewayOnLink = true;
            };
          }
          {
            routeConfig = {
              Gateway = "10.0.0.1";
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
        };
        wireguardPeers = [
          # akane
          {
            wireguardPeerConfig = {
              # NB 28d = 00011100b = 1Ch, damn IPv4 subnets are not easy.
              # That said, we can use 28–31 for a /16 subnet.
              AllowedIPs = [
                "2a12:5940:7226:ff00::/56"
                "172.28.0.0/14"
              ];
              RouteTable = "main";
              PublicKey = "gvAPp/g475vG9Jpj9b4rdPKPwhIKvuxynuw8EffMrGk=";
              PresharedKeyFile = config.sops.secrets."wireguard/psk.txt".path;
            };
          }
          # eerie (TODO: remove after rolling out akane)
          {
            wireguardPeerConfig = {
              AllowedIPs = [
                "2a12:5940:7226:1000::face/128"
                "172.16.0.3/32"
              ];
              RouteTable = "main";
              PublicKey = "UaXdcPYo2GiqdXgaxlkGpeKQKO7casrRR9eJCZs5RVs=";
              PresharedKeyFile = config.sops.secrets."wireguard/psk.txt".path;
            };
          }
        ];
      };
    };
  };

  # See https://superuser.com/a/1728017
  services.ndppd = {
    enable = true;
    proxies."ens3".rules."2a12:5940:7226::/48".method = "static";
  };
}
