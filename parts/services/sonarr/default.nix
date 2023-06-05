{ lib, pkgs, config, ... }:
let
  cfg = config.services.sonarr;
in
{
  disabledModules = [ "services/misc/sonarr.nix" ];

  options.services.sonarr = {
    enable = lib.mkEnableOption (lib.mdDoc "Sonarr");
    package = lib.mkPackageOptionMD pkgs "sonarr" { };

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = lib.mdDoc ''
        User account under which Sonarr runs. If set to `null`,
        `sonarr` user is set up.
      '';
    };

    group = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = lib.mdDoc ''
        Group account under which Sonarr runs. If set to `null`,
        `sonarr` group is set up.
      '';
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = lib.mdDoc ''
        Additional groups under which Sonarr runs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.sonarr = {
      description = "Sonarr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";

        ExecStartPre = pkgs.writeShellScript "sonarr-setup" ''
          cd "$STATE_DIRECTORY"
          mkdir -p data media
          chmod u=rwx,g=,o= data
        '';
        ExecStart = "${cfg.package}/bin/NzbDrone --nobrowser --data=\${STATE_DIRECTORY}/data";

        User =
          if cfg.user != null then cfg.user
          else config.users.users.sonarr.name;
        Group =
          if cfg.group != null then cfg.group
          else config.users.groups.sonarr.name;

        SupplementaryGroups = cfg.extraGroups;

        StateDirectory = "sonarr";
        StateDirectoryMode = "0750"; # u=rwx,g=rx,o=

        UMask = "0027"; # u=rwx,g=rx,o=
      };
    };

    users = {
      users.sonarr = lib.mkIf (cfg.user == null) {
        isSystemUser = true;
        group =
          if cfg.group != null then cfg.group
          else config.users.groups.sonarr.name;
      };
      groups.sonarr = lib.mkIf (cfg.group == null) {
        members = lib.singleton
          (if cfg.user != null then cfg.user
          else config.users.users.sonarr.name);
      };
    };
  };
}
