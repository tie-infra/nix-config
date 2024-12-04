{
  config,
  lib,
  utils,
  pkgs,
  ...
}:
let
  cfg = config.services.mcactivity;

  settingsFormat = pkgs.formats.json { };
  settingsFile = settingsFormat.generate "settings.json" cfg.settings;
in
{
  options.services.mcactivity = {
    enable = lib.mkEnableOption (lib.mdDoc "MCActivity Discord Bot");
    package = lib.mkPackageOptionMD pkgs "mcactivity" { };
    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = lib.mdDoc ''
        Structured MCActivity service configuration.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mcactivity = {
      description = "MCActivity Discord Bot";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";

        Restart = "always";

        ExecStart = utils.escapeSystemdExecArgs [
          (lib.getExe cfg.package)
          (builtins.toString settingsFile)
        ];

        DynamicUser = true;
        UMask = "0077";

        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        DeviceAllow = "";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;

        SystemCallFilter = [
          "@system-service"
          "~@resources"
          "~@privileged"
        ];
        SystemCallErrorNumber = "EPERM";
        SystemCallArchitectures = "native";
      };
    };
  };
}
