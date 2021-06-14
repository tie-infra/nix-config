{ config, lib, ... }: {
  services.tor = {
    enable = true;
    openFirewall = true;

    relay = {
      enable = true;
      role = "relay";
    };

    settings = {
      Nickname = "saitama";
      ContactInfo = "legal@b1nary.tk";

      MaxAdvertisedBandwidth = "1024 KBytes";

      # Enable more ExtraInfoStatistics.
      CellStatistics = true;
      EntryStatistics = true;
      ConnDirectionStatistics = true;

      # Default is 30 seconds.
      ShutdownWaitLength = 5;

      # "Configured public relay to listen only on an IPv6 address. Tor needs to listen on an IPv4 address too.".
      #
      # For now let’s listen on IPv4 too. Also Tor can’t automatically discover IPv6 address.
      # And, yeah, and DirPort doesn’t even work with IPv6.
      #
      # TODO: actually, let’s move Tor service to another box. I don’t think Tor
      # will support IPv6-only relays anytime soon. So it’s easier to add another
      # server with dual-stack connectivity just for the Tor daemon. I really don’t
      # want any IPv4 traffic on main network.
      #
      ORPort = [
        {
          addr = "0.0.0.0";
          port = 9001;
        }
        {
          addr = "[2a02:2168:8fec:f600::39f]";
          port = 9001;
        }
      ];
      DirPort = [{ port = 9002; }];

      # Huh, "Servers must be able to freely connect to the rest of the Internet, […]".
      #ClientUseIPv4 = false;
      ClientUseIPv6 = true;
    };
  };
}

# # Below is the config before NixOS transition.
#
# Nickname tatsuya
# ContactInfo legal@b1nary.tk
#
# #ExitRelay 1
# #IPv6Exit 1
# ExitRelay 0
# ExitPolicy reject *:*
# MaxAdvertisedBandwidth 512 KBytes
#
# Address tornetwork.b1nary.tk
#
# DirPort 9002
#
# ORPort 9001
# ORPort [::]:9001
#
# TransPort [::]:9040
# TransPort 0.0.0.0:9040
#
# ClientUseIPv4 1
# ClientUseIPv6 1
# ClientPreferIPv6ORPort 1
# ClientPreferIPv6DirPort 1
#
# # We are (were) also using Tor on the local net for Internet censorship circumvention.
# #ExitPolicyRejectLocalInterfaces 1
# #ExitPolicy reject *:25 # no mail
# #ExitPolicy reject *:53 # no DNS
# #ExitPolicy reject *:80 # no HTTP
# #ExitPolicy reject private:*
# #ExitPolicy accept *:*
#
# SocksPort [::]:9050
# SocksPort 0.0.0.0:9050
#
# DNSPort [::1]:9053
# DNSPort 127.0.0.1:9053
#
# # Tor hidden services from the local net
# VirtualAddrNetworkIPv4 172.16.0.0/12
# AutomapHostsOnResolve 1
#
# NoExec 1
# #Sandbox 1
