{ lib, pkgs, config, ... }:
let
  cfg = config.services.flood;
in
{
  options.services.flood = {
    enable = lib.mkEnableOption (lib.mdDoc "Flood");
    package = lib.mkPackageOptionMD pkgs "flood" { };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--auth=none" ];
      description = lib.mdDoc ''
        Extra flags passed to the Flood command in the service definition.
      '';
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = lib.mdDoc ''
        Additional groups under which Flood runs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.flood = {
      description = "Flood";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      # For media info detection functionality.
      path = [ pkgs.mediainfo ];

      serviceConfig = {
        Type = "exec";
        Restart = "always";

        ExecStart = ''
          ${lib.getExe' cfg.package "flood"} \
            --rundir ''${STATE_DIRECTORY} \
            ${lib.escapeShellArgs cfg.extraFlags}
        '';

        DynamicUser = true;
        SupplementaryGroups = cfg.extraGroups;

        StateDirectory = "flood";
        StateDirectoryMode = "0700";

        UMask = "0077";
      };
    };
  };
}
