{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.mcp-atlassian;
in
{
  options.services.mcp-atlassian = {
    enable = lib.mkEnableOption "mcp-atlassian";

    package = lib.mkPackageOption pkgs "mcp-atlassian" { };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Environment variables for mcp-atlassian.

        See <https://mcp-atlassian.soomiles.com/docs/configuration#environment-variables>
      '';
      example = lib.literalExpression ''
        {
          JIRA_URL = "https://your-domain.atlassian.net";
          JIRA_USERNAME = "user@example.com";
          JIRA_API_TOKEN = "your-api-token";
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mcp-atlassian = {
      description = "mcp-atlassian MCP Server";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      inherit (cfg) environment;

      serviceConfig = {
        Type = "exec";

        ExecSearchPath = lib.makeBinPath [ cfg.package ];
        ExecStart = "mcp-atlassian";

        DynamicUser = true;

        Restart = "always";
        RestartSec = "5s";

        # Security hardening similar to vaultwarden
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        DevicePolicy = "closed";
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
        ProtectProc = "noaccess";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
      };
    };
  };
}
