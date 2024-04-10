{ lib, pkgs, ... }:
let
  package = pkgs.systemd;
  address = "kazuma.tie.rip:25521";
in
{
  config = {
    systemd.sockets.minecraft-ddss = {
      unitConfig.Description = "Minecraft DDSS socket";
      wantedBy = [ "sockets.target" ];
      listenStreams = [ "22521" ];
    };
    systemd.services.minecraft-ddss = {
      description = "Minecraft DDSS socket proxy";
      wantedBy = [ "multi-user.target" ];
      requires = [ "minecraft-ddss.socket" ];
      after = [ "minecraft-ddss.socket" ];

      serviceConfig = {
        # TODO: "notify" is available since v254, we have v253;
        # change after upgrading to NixOS 23.11.
        Type = "exec";

        ExecStart = "${package}/lib/systemd/systemd-socket-proxyd ${lib.escapeShellArg address}";

        Environment = [ "SYSTEMD_LOG_LEVEL=debug" ];

        DynamicUser = true;
        UMask = "0777";
        DeviceAllow = "";
        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectClock = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ProtectProc = "noaccess";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateTmp = true;
        PrivateDevices = false; # for hardware acceleration
        PrivateMounts = true;
        PrivateUsers = true;
        RemoveIPC = true;
        SystemCallFilter = [ "@system-service" ];
        SystemCallErrorNumber = "EPERM";
        SystemCallArchitectures = "native";
      };
    };
  };
}
