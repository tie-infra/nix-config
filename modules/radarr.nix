{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.radarr;
in
{
  options.services.radarr = {
    enable = lib.mkEnableOption (lib.mdDoc "Radarr");
    package = lib.mkPackageOptionMD pkgs "radarr" { };

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = lib.mdDoc ''
        User account under which Radarr runs. If set to `null`,
        `radarr` user is set up.
      '';
    };

    group = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = lib.mdDoc ''
        Group account under which Radarr runs. If set to `null`,
        `radarr` group is set up.
      '';
    };

    mediaFolders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = lib.mdDoc ''
        Additional media folders to create under the root folder.
      '';
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = lib.mdDoc ''
        Additional groups under which Radarr runs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.radarr = {
      description = "Radarr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
        Restart = "always";

        ExecStartPre = pkgs.writeShellScript "radarr-setup" ''
          cd "$STATE_DIRECTORY"
          mkdir -p data media
          ${lib.concatLines (
            map (folder: ''
              mkdir -p media/${lib.escapeShellArg folder}
            '') cfg.mediaFolders
          )}
          chmod u=rwx,g=,o= data
        '';

        ExecStart = "${lib.getExe' cfg.package "Radarr"} --nobrowser --data=\${STATE_DIRECTORY}/data";

        User = if cfg.user != null then cfg.user else config.users.users.radarr.name;
        Group = if cfg.group != null then cfg.group else config.users.groups.radarr.name;

        SupplementaryGroups = cfg.extraGroups;

        StateDirectory = "radarr";
        StateDirectoryMode = "0750"; # u=rwx,g=rx,o=

        UMask = "0027"; # u=rwx,g=rx,o=
      };
    };

    users = {
      users.radarr = lib.mkIf (cfg.user == null) {
        isSystemUser = true;
        group = if cfg.group != null then cfg.group else config.users.groups.radarr.name;
      };
      groups.radarr = lib.mkIf (cfg.group == null) {
        members = lib.singleton (if cfg.user != null then cfg.user else config.users.users.radarr.name);
      };
    };
  };
}
