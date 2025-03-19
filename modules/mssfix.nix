{ config, lib, ... }:
let
  cfg = config.networking.mssfix;
in
{
  options.networking.mssfix = {
    enable = lib.mkEnableOption "TCP MSS clamping to PMTU for forwarded packets";
  };

  config = lib.mkIf cfg.enable {
    # https://netfilter.org/projects/nftables/manpage.html#:~:text=change%20tcp%20mss
    # https://wiki.nftables.org/wiki-nftables/index.php/Mangling_packet_headers#Mangling_TCP_options
    # https://k1024.org/posts/2023/2023-04-16-nftables-tcp-clamp-mss
    networking.nftables.tables.nixos-mssfix = lib.mkIf config.networking.nftables.enable {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority mangle; policy accept;
          tcp flags syn tcp option maxseg size set rt mtu
        }
      '';
    };

    # https://ipset.netfilter.org/iptables-extensions.man.html#:~:text=alter%20the%20MSS%20value%20of%20TCP%20SYN
    networking.firewall = lib.mkIf (!config.networking.nftables.enable) rec {
      extraCommands = ''
        ${extraStopCommands}
        ip46tables -t mangle -N nixos-mssfix
        ip46tables -t mangle -A nixos-mssfix -p tcp --syn -j TCPMSS --clamp-mss-to-pmtu
        ip46tables -t mangle -A FORWARD -j nixos-mssfix
      '';
      extraStopCommands = ''
        ip46tables -t mangle -D FORWARD -j nixos-mssfix 2>/dev/null || true
        ip46tables -t mangle -F nixos-mssfix 2>/dev/null || true
        ip46tables -t mangle -X nixos-mssfix 2>/dev/null || true
      '';
    };
  };
}
