{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.xray;

  settingsFormat = pkgs.formats.json { };
  configFile = settingsFormat.generate "xray.json" cfg.settings;
in
{
  options.services.xray = {
    enable = lib.mkEnableOption "Xray server";
    package = lib.mkPackageOption pkgs "xray" { };
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
      };
      example = {
        inbounds = [
          {
            port = 1080;
            listen = "::1";
            protocol = "http";
          }
        ];
        outbounds = [
          {
            protocol = "freedom";
          }
        ];
      };
      description = ''
        The configuration object.

        See <https://xtls.github.io/config>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.xray = {
      description = "Xray server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment.CONFIG_FILE = configFile;
      serviceConfig = {
        Type = "exec";
        Restart = "always";
        DynamicUser = true;
        ExecStart = "xray -config \${CONFIG_FILE}";
        ExecSearchPath = [ (lib.makeBinPath [ cfg.package ]) ];
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
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
        UMask = "0007"; # u=rwx,g=rwx,o=
      };
    };
  };
}
