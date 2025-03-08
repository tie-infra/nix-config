{ config, lib, ... }:
let
  cfg = config.networking.tcpmssClamping;
in
{
  options.networking.tcpmssClamping = {
    enable = lib.mkEnableOption "TCP MSS clamping to PMTU";
  };

  config = lib.mkIf cfg.enable {
    # Clamp TCP MSS to PMTU for forwarded packets.
    # https://wiki.nftables.org/wiki-nftables/index.php/Mangling_packet_headers#Mangling_TCP_options
    # https://k1024.org/posts/2023/2023-04-16-nftables-tcp-clamp-mss
    networking.nftables.tables.tcpmss = {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority mangle; policy accept;
          tcp flags syn tcp option maxseg size set rt mtu
        }
      '';
    };
  };
}
