# See https://klub.com.pl/dhcpv6/doc/dibbler-user.pdf

{ config, lib, pkgs, ... }:
let
  name = "dibbler-client";
  cfg = config.networking.${name};
in {
  options.networking.${name} = {
    enable = lib.mkEnableOption name;

    inactiveMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        This enables so called inactive mode. When server begins operation and
        it detects that required interfaces are not ready, error message is
        printed and server exits. However, if inactive mode is enabled, server
        sleeps instead and wait for required interfaces to become operational.
        That is a useful feature, when using wireless interfaces, which take
        some time to initialize as associate.
      '';
    };

    scriptPath = lib.mkOption {
      type = types.nullOr lib.types.str;
      default = null;
      description = ''
        Takes one string parameter that specifies name of a script that will be
        called every time something important happens in a system, e.g. when
        address or prefix is assigned, updated or released.
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Extra configuration text append to client.conf configuration file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.${name} = {
      description = "Portable DHCPv6 client";
      wantedBy = [ "multi-user.target" "network-online.target" ];
      wants = [ "network.target" ];
      before = [ "network-online.target" ];
      unitConfig.ConditionCapability = "CAP_NET_ADMIN";
      serviceConfig = {
        Type = "exec";
        ExecStart = "${pkgs.dibbler}/bin/dibbler-client run";
        Restart = "always";
        PrivateTmp = true;
      };
    };

    environment.etc."dibbler/client.conf".text = ''
      ${lib.optionalString (cfg.inactiveMode) "inactive-mode"}
      ${lib.optionalString (cfg.scriptPath != null) "script ${cfg.scriptPath}"}
      ${cfg.extraConfig}
    '';
  };
}
