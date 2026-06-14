{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.garage-webui;
in
{
  options.services.garage-webui = {
    enable = lib.mkEnableOption "Garage Web UI";
    package = lib.mkPackageOption pkgs "garage-webui" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.garage-webui = {
      description = "Garage Web UI";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "exec";
        Restart = "on-failure";

        ExecSearchPath = lib.makeBinPath [ cfg.package ];
        ExecStart = "garage-webui";

        DynamicUser = true;
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
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
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
