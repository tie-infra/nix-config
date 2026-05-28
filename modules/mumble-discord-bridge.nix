{
  config,
  lib,
  utils,
  pkgs,
  ...
}:
let
  cfg = config.services.mumble-discord-bridge;
in
{
  options.services.mumble-discord-bridge = {
    enable = lib.mkEnableOption "Mumble Discord bridge";
    package = lib.mkPackageOption pkgs "mumble-discord-bridge" { };
    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Extra options to pass to mumble-discord-bridge. See the docs:
        <https://github.com/Stieneee/mumble-discord-bridge?tab=readme-ov-file#usage>
        and {command}`mumble-discord-bridge -help` for more information.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mumble-discord-bridge = {
      description = "Mumble Discord bridge";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "exec";
        Restart = "always";
        DynamicUser = true;
        ExecStart = utils.escapeSystemdExecArgs (
          [
            "mumble-discord-bridge"
          ]
          ++ cfg.args
        );
        ExecSearchPath = [ (lib.makeBinPath [ cfg.package ]) ];
        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "full";
        RestrictAddressFamilies = "~AF_PACKET AF_NETLINK";
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "@system-service";
        UMask = "0027"; # u=rwx,g=rx,o=
      };
    };
  };
}
