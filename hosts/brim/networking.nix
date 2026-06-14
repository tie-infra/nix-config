{
  lib,
  pkgs,
  ...
}:
{
  networking = {
    hostName = "brim";
    firewall = {
      allowedTCPPorts = [
        # PufferPanel SFTP
        5657
      ];
      allowedTCPPortRanges = [
        # Minecraft
        {
          from = 25500;
          to = 25599;
        }
      ];
      allowedUDPPorts = [
        # Minecraft SimpleVoiceChat
        24454
        24455
      ];
    };
  };

  systemd.network.networks."10-wan" = {
    matchConfig = {
      Name = "enp3s0f0";
    };
    networkConfig = {
      Address = [
        "185.148.38.208/26"
        "2a00:f440:0:614::11/64"
        "2a00:f440:0:614::12/64"
        "2a00:f440:0:614::13/64"
        "2a00:f440:0:614::14/64"
        "2a00:f440:0:614::15/64"
        "2a00:f440:0:614::16/64"
        "2a00:f440:0:614::17/64"
        "2a00:f440:0:614::18/64"
        "2a00:f440:0:614::19/64"
        "2a00:f440:0:614::1a/64"
        "2a00:f440:0:614::1b/64"
        "2a00:f440:0:614::1c/64"
        "2a00:f440:0:614::1d/64"
        "2a00:f440:0:614::1e/64"
        "2a00:f440:0:614::1f/64"
      ];
      Gateway = [
        "185.148.38.193"
        "2a00:f440:0:614::1"
      ];
      DNS = [
        "93.95.97.2"
        "93.95.100.20"
      ];
    };
    linkConfig = {
      RequiredForOnline = "routable";
    };
  };

  services.nfqws = {
    enable = true;
    instances."" = {
      settings.qnum = 200;
      profiles."".settings =
        let
          fakeGoogleQUIC = pkgs.copyPathToStore ../../zapret/quic_initial_www_google_com.bin;
          fakeGithubTLS = pkgs.copyPathToStore ../../zapret/tls_clienthello_github_com.bin;
          fakeStun = pkgs.copyPathToStore ../../zapret/stun.bin;
        in
        {
          dpi-desync = "fake";
          dpi-desync-fake-quic = fakeGoogleQUIC;
          dpi-desync-fake-tls = [
            fakeStun
            fakeGithubTLS
          ];
          dpi-desync-fooling = "ts";

          hostlist = map pkgs.copyPathToStore [
            ../../zapret/discord-domains.txt
          ];
          hostlist-domains = lib.concatStringsSep "," [
            "cloudflare-ech.com" # TLS ECH
            "cloudflare.com"
            "repo.nickuc.com"
          ];
        };
    };
  };

  # https://github.com/bol-van/zapret?tab=readme-ov-file#nftables-для-nfqws
  networking.nftables.tables.zapret = {
    family = "inet";
    content = ''
      chain pre {
        type filter hook prerouting priority filter;
        tcp sport {80,443} ct reply packets 1-3 queue num 200 bypass
      }
      chain post {
        type filter hook postrouting priority mangle;
        meta mark and 0x40000000 == 0 tcp dport {80,443} ct original packets 1-6 queue num 200 bypass
        meta mark and 0x40000000 == 0 udp dport 443 ct original packets 1-6 queue num 200 bypass
      }
    '';
  };

  boot.kernel.sysctl."net.netfilter.nf_conntrack_tcp_be_liberal" = true;
}
