{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.mumble-server;

  settingsFormat = pkgs.formats.iniWithGlobalSection { };
  configFile = settingsFormat.generate "mumble-server.ini" cfg.settings;
in
{
  options.services.mumble-server = {
    enable = lib.mkEnableOption "Mumble server";
    package = lib.mkPackageOption pkgs "murmur" { };
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mumble-server = {
      description = "Mumble server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment.CONFIG_FILE = configFile;
      environment.HOME = "%S/mumble-server";
      serviceConfig = {
        Type = "exec";
        Restart = "always";
        DynamicUser = true;
        ExecStart = "mumble-server -fg -ini \${CONFIG_FILE}";
        ExecSearchPath = [ (lib.makeBinPath [ cfg.package ]) ];
        StateDirectory = "mumble-server";
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
        UMask = "0027"; # u=rwx,g=rx,o=
      };
    };
  };
}
