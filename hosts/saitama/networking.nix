{ config, ... }: {
  networking = {
    hostName = "saitama";
    hostId = "c2e4086f";

    # Suppress dmesg log spam.
    firewall.logRefusedConnections = false;

    # We are in native IPv6 dual-stack network.
    enableIPv6 = true;

    # Disable default DHCP, otherwise NixOS tries to lease DHCP
    # addresses on all available interfaces. The docs also state
    # that this behavior will eventually be deprecated and removed.
    useDHCP = false;

    # Enable systemd-networkd instead of default networking scripts.
    useNetworkd = true;
  };

  # FIXME: systemd discards leases on reboot https://github.com/systemd/systemd/issues/16924
  # That’s a real issue since network’s DHCP server DOES NOT assign new addresses for the
  # same MAC address (and DUID?) until the last lease expires. We’d need something like a
  # patch from https://github.com/systemd/systemd/pull/16920
  #
  # And the root cause is that DHCPv6 client apparently does not release addresses on shutdown.
  # See also https://github.com/systemd/systemd/issues/19728
  #
  systemd.network = {
    enable = true;

    networks."90-ipv4" = {
      matchConfig.Name = "enp2s0";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv4";
      };
    };

    networks."90-ipv6" = {
      matchConfig.Name = "enp3s0";
      networkConfig = {
        DHCP = "ipv6";
        IPv6AcceptRA = true;
        LinkLocalAddressing = "ipv6";
      };
    };
  };

  environment.etc."systemd/networkd.conf".text = ''
    [Network]
    SpeedMeter=yes
  '';
}
