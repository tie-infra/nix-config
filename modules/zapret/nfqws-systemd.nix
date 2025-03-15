{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    any
    attrNames
    makeBinPath
    mapAttrs'
    mkIf
    nameValuePair
    ;

  cfg = config.services.nfqws;

  serviceConfig = {
    Type = "notify";
    Restart = "on-failure";

    ExecSearchPath = makeBinPath [ cfg.package ];
    ExecStart = "nfqws @\${CONFIG_FILE}";

    StateDirectory = "nfqws-%i";
    StateDirectoryMode = "0700";
    WorkingDirectory = "%S/nfqws-%i";

    DynamicUser = true;
    UMask = "0077";
    AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_RAW";
    CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_RAW";

    PrivateTmp = true;
    PrivateMounts = true;
    PrivateDevices = true;
    ProtectHome = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    ProtectSystem = "strict";
    ProtectProc = "invisible";
    ProcSubset = "pid";
    RemoveIPC = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    MemoryDenyWriteExecute = true;
    LockPersonality = true;
    RestrictAddressFamilies = "AF_NETLINK AF_UNIX AF_INET6 AF_INET";
    SystemCallFilter = [
      "@system-service"
      "~@resources"
    ];
  };
in
{
  config = mkIf cfg.enable {
    systemd.services =
      {
        "nfqws@" = mkIf (any (x: x != "") (attrNames cfg.instances)) {
          enable = true;
          inherit serviceConfig;
        };
      }
      // (mapAttrs' (
        name': config':
        let
          useDropin = name' != "";
          serviceName = if useDropin then "nfqws@" + name' else "nfqws";
          systemdService =
            if useDropin then
              {
                wantedBy = [ "multi-user.target" ];
                environment.CONFIG_FILE = config'.configFile;
                overrideStrategy = "asDropin";
              }
            else
              {
                wantedBy = [ "multi-user.target" ];
                environment.CONFIG_FILE = config'.configFile;
                serviceConfig = serviceConfig // {
                  StateDirectory = "nfqws";
                  WorkingDirectory = "%S/nfqws";
                };
              };
        in
        nameValuePair serviceName (mkIf config'.enable systemdService)
      ) cfg.instances);
  };
}
