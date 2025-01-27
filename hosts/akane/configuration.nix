{
  config,
  lib,
  pkgs,
  ...
}:
let
  ispInterface = "vl-isp";
  lanInterface = "vl-lan";

  lanVlanId = 1;
  ispVlanId = 2;

  bridgeInterface = "br0";
  wireguardInterface = "wg0";

  wireguardEndpoint = "falcon.tie.rip:51820";
  wireguardConfiguration = [
    {
      cidr = "2a01:4f8:222:fee0::1/60";
      address = "2a01:4f8:222:fee0::1";
      network = "2a01:4f8:222:fee0::/60";
    }
    {
      cidr = "172.28.0.1/14";
      address = "172.28.0.1";
      network = "172.28.0.0/14";
    }
  ];

  # tempAddr: manage temporary addresses
  # radv: set up router advertisements
  # dhcpv4: set up DHCPv4 server
  lanConfiguration = [
    {
      cidr = "2a01:4f8:222:feed::1/64";
      address = "2a01:4f8:222:feed::1";
      network = "2a01:4f8:222:feed::/64";
      tempAddr = true;
      radv = true;
    }
    {
      cidr = "fddb:eeb7:b646:feed::1/64";
      address = "fddb:eeb7:b646:feed::1";
      network = "fddb:eeb7:b646:feed::/64";
      radv = true;
    }
    {
      cidr = "172.31.0.1/16";
      address = "172.31.0.1";
      network = "172.31.0.0/16";
      dhcpv4 = true;
    }
  ];

  lanConfigurationAddresses = map ({ address, ... }: address) lanConfiguration;
  lanConfigurationAddressesIpv4 = lib.filter (lib.hasInfix ".") lanConfigurationAddresses;
  lanConfigurationAddressesIpv6 = lib.filter (lib.hasInfix ":") lanConfigurationAddresses;
in
{
  system.stateVersion = "23.11";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    kernel.sysctl = {
      # Note: IPForward in systemd.network sets this too despite being defined
      # per each network. However, it also affects defaults for some other
      # options in network configuration, e.g. not accepting IPv6 RAs (see
      # IPv6AcceptRA) when IPForward is set. This is a weird design decision
      # systemd-networkd made. Let’s be explicit about forwarding being a global
      # option.
      "net.ipv4.ip_forward" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    initrd.availableKernelModules = [ "ahci" ];
  };

  environment.machineInfo = {
    chassis = "server";
    location = "Ivan’s homelab";
    hardwareVendor = "Qotom";
    hardwareModel = "Q1076GE";
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    traceroute
    tcpdump
    iperf3
  ];

  profiles.btrfs-erase-your-darlings = {
    enable = true;
    bootDisk = "/dev/disk/by-uuid/7F67-589D";
    rootDisk = "/dev/disk/by-uuid/5b169687-13c2-4357-9cfc-d7ecba357db0";
  };

  networking.hostName = "akane";

  networking.firewall.allowedTCPPorts = [
    # Netdata
    19999
  ];

  networking.firewall.interfaces.${lanInterface} = {
    allowedUDPPorts = [
      # DHCPv4
      67
      # DNS
      53
      # Multicast DNS
      5353
    ];
    allowedTCPPorts = [
      # DNS
      53
    ];
  };

  # Clamp TCP MSS to PMTU for forwarded packets.
  # https://wiki.nftables.org/wiki-nftables/index.php/Mangling_packet_headers#Mangling_TCP_options
  networking.nftables.tables.tcpmss = {
    family = "inet";
    content = ''
      chain forward {
        type filter hook forward priority 0;
        tcp flags syn tcp option maxseg size set rt mtu
      }
    '';
  };

  systemd.network.config = {
    routeTables = {
      wireguard = 1000;
    };
  };

  systemd.network.netdevs."10-bridge" = {
    netdevConfig = {
      Name = bridgeInterface;
      Kind = "bridge";
    };
    bridgeConfig = {
      DefaultPVID = "none";
      VLANFiltering = true;
    };
  };

  systemd.network.netdevs."10-lan" = {
    netdevConfig = {
      Name = lanInterface;
      Kind = "vlan";
    };
    vlanConfig = {
      Id = lanVlanId;
    };
  };

  systemd.network.netdevs."10-isp" = {
    netdevConfig = {
      Name = ispInterface;
      Kind = "vlan";
    };
    vlanConfig = {
      Id = ispVlanId;
    };
  };

  systemd.network.netdevs."10-wg" = {
    netdevConfig = {
      Name = wireguardInterface;
      Kind = "wireguard";
    };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets."wireguard/pk.txt".path;
      H1 = 224412;
      H2 = 52344123;
      H3 = 6713390;
      H4 = 2537922;
    };
    wireguardPeers = [
      {
        AdvancedSecurity = true;
        AllowedIPs = [
          "::/0"
          "0.0.0.0/0"
        ];
        RouteTable = "wireguard";
        PublicKey = "8LgfPosHOG0SpUGqIlYesskq00Y6wihLtgZFUkutdE0=";
        Endpoint = wireguardEndpoint;
        PresharedKeyFile = config.sops.secrets."wireguard/psk.txt".path;
        PersistentKeepalive = 30;
      }
    ];
  };

  systemd.network.networks."10-bridge" = {
    matchConfig = {
      Name = bridgeInterface;
    };
    networkConfig = {
      VLAN = [
        ispInterface
        lanInterface
      ];
      ConfigureWithoutCarrier = true;
      # https://github.com/systemd/systemd/issues/575#issuecomment-163810166
      LinkLocalAddressing = false;
    };
    bridgeVLANs = [
      { VLAN = lanVlanId; }
      { VLAN = ispVlanId; }
    ];
    linkConfig = {
      RequiredForOnline = "no-carrier:carrier";
    };
  };

  systemd.network.networks."10-bridge-lan" = {
    matchConfig = {
      Name = [
        "enp3s0"
        "enp4s0"
        "enp5s0"
        "enp6s0"
        "enp7s0"
        "enp8s0"
        "enp9s0"
      ];
    };
    networkConfig = {
      Bridge = bridgeInterface;
      ConfigureWithoutCarrier = true;
    };
    bridgeVLANs = [
      {
        PVID = lanVlanId;
        EgressUntagged = lanVlanId;
      }
      # Allow downstream devices to access ISP network.
      { VLAN = ispVlanId; }
    ];
    linkConfig = {
      RequiredForOnline = "no-carrier:enslaved";
    };
  };

  systemd.network.networks."10-bridge-isp" = {
    matchConfig = {
      Name = [ "enp2s0" ];
    };
    networkConfig = {
      Bridge = bridgeInterface;
      ConfigureWithoutCarrier = true;
    };
    bridgeVLANs = [
      {
        PVID = ispVlanId;
        EgressUntagged = ispVlanId;
      }
    ];
    linkConfig = {
      RequiredForOnline = "no-carrier:enslaved";
    };
  };

  systemd.network.networks."10-lan" = {
    matchConfig = {
      Name = lanInterface;
    };
    networkConfig = {
      ConfigureWithoutCarrier = true;
      IPv6PrivacyExtensions = true;
      IPv6AcceptRA = false;
      IPv6SendRA = true;
      DHCPServer = true;
      MulticastDNS = true;
      LLMNR = true;
    };
    dhcpServerConfig = {
      DNS = lanConfigurationAddressesIpv4;
    };
    ipv6SendRAConfig = {
      RetransmitSec = 1800; # 30 minutes
      DNS = lanConfigurationAddressesIpv6;
    };
    addresses =
      let
        makeAddress =
          {
            cidr,
            tempAddr ? false,
            ...
          }:
          {
            Address = cidr;
            AddPrefixRoute = false;
          }
          // lib.optionalAttrs tempAddr { ManageTemporaryAddress = true; };
      in
      map makeAddress lanConfiguration;
    routes =
      let
        makeRoute =
          { network, address, ... }:
          {
            Destination = network;
            PreferredSource = address;
          };
        routes = map makeRoute lanConfiguration;
        withTable = routeTable: routeConfig: routeConfig // { Table = routeTable; };
      in
      routes ++ map (withTable "wireguard") routes;
    ipv6Prefixes =
      let
        makeIPv6Prefix =
          { network, ... }:
          {
            Prefix = network;
          };
        radv = lib.filter (
          {
            radv ? false,
            ...
          }:
          radv
        ) lanConfiguration;
      in
      map makeIPv6Prefix radv;
    # NB seems to be working fine without IPv6RoutePrefix.
    ipv6RoutePrefixes =
      let
        makeIPv6RoutePrefix =
          { network, ... }:
          {
            Route = network;
          };
        radv = lib.filter (
          {
            radv ? false,
            ...
          }:
          radv
        ) lanConfiguration;
      in
      map makeIPv6RoutePrefix radv;
    linkConfig = {
      RequiredForOnline = "no-carrier:routable";
    };
  };

  systemd.network.networks."10-isp" = {
    matchConfig = {
      Name = ispInterface;
    };
    networkConfig = {
      DHCP = true;
      IPv6PrivacyExtensions = true;
      MulticastDNS = false;
      LLMNR = false;
      DNSOverTLS = true;
      DNSSEC = true;
      DNS = [
        "2620:fe::fe#dns.quad9.net"
        "2620:fe::9#dns.quad9.net"
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
      ];
    };
    ipv6AcceptRAConfig = {
      UseDNS = false;
    };
    dhcpV6Config = {
      UseDelegatedPrefix = false;
      UseDNS = false;
    };
    dhcpV4Config = {
      UseDNS = false;
    };
    linkConfig = {
      RequiredForOnline = "routable";
    };
  };

  systemd.network.networks."10-wg" = {
    matchConfig = {
      Name = wireguardInterface;
    };
    addresses =
      let
        makeAddress =
          { cidr, ... }:
          {
            Address = cidr;
            AddPrefixRoute = false;
          };
      in
      map makeAddress wireguardConfiguration;
    routes =
      let
        makeRoute =
          { network, address, ... }:
          {
            Destination = network;
            PreferredSource = address;
          };
      in
      map makeRoute wireguardConfiguration;
    routingPolicyRules =
      let
        makeRoutingPolicyRule =
          { network, ... }:
          {
            From = network;
            Table = "wireguard";
            Priority = 1000;
          };
      in
      map makeRoutingPolicyRule wireguardConfiguration;
    linkConfig = {
      RequiredForOnline = "carrier:routable";
    };
  };

  services.resolved = {
    extraConfig =
      lib.concatLines (map (address: "DNSStubListenerExtra=" + address) lanConfigurationAddresses)
      + ''
        StaleRetentionSec=1d
      '';
  };

  services = {
    fstrim.enable = true;
    netdata.enable = true;
  };

  systemd.services.systemd-networkd = {
    serviceConfig = {
      SupplementaryGroups = [ config.users.groups.keys.name ];
      # Uncomment to enable verbose logging for systemd-networkd.
      #Environment = [ "SYSTEMD_LOG_LEVEL=debug" ];
    };
  };

  sops.secrets = {
    "wireguard/pk.txt" = {
      mode = "0440";
      group = config.users.groups.systemd-network.name;
      reloadUnits = [ config.systemd.services.systemd-networkd.name ];
      sopsFile = ../../secrets/wireguard-pk-akane.sops.yaml;
    };
    "wireguard/psk.txt" = {
      mode = "0440";
      group = config.users.groups.systemd-network.name;
      reloadUnits = [ config.systemd.services.systemd-networkd.name ];
      sopsFile = ../../secrets/wireguard-psk.sops.yaml;
    };
  };
}
