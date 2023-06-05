{ lib, pkgs, config, ... }:
let
  cfg = config.services.minio;
in
{
  disabledModules = [ "services/web-servers/minio.nix" ];

  options.services.minio = {
    enable = lib.mkEnableOption (lib.mdDoc "Minio Object Storage");
    package = lib.mkPackageOptionMD pkgs "minio" { };

    listenAddress = lib.mkOption {
      default = ":9000";
      type = lib.types.str;
      description = lib.mdDoc "IP address and port of the server.";
    };

    consoleAddress = lib.mkOption {
      default = ":9001";
      type = lib.types.str;
      description = lib.mdDoc "IP address and port of the web UI (console).";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''
        {
          MINIO_SITE_REGION = "us-east-1";
          MINIO_BROWSER = "off";
        }
      '';
      description = lib.mdDoc ''
        Environment variables to set for the service. Secrets should be
        specified using {option}`environmentFile`.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = lib.mdDoc ''
        File to load environment variables from. Loaded variables override
        values set in {option}`environment`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.minio = {
      description = "Minio Object Storage";
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = cfg.environment;

      serviceConfig = {
        Type = "notify";
        Restart = "always";

        ExecStart = pkgs.writeShellScript "minio" ''
          set -eu
          export HOME="$STATE_DIRECTORY"
          exec ${lib.getExe cfg.package} server --json \
            --address ${cfg.listenAddress} \
            --console-address ${cfg.consoleAddress} \
            --config-dir="$STATE_DIRECTORY"/config \
            --certs-dir="$STATE_DIRECTORY"/certs \
            "$STATE_DIRECTORY"/data
        '';

        StateDirectory = "minio";
        StateDirectoryMode = "0700";

        EnvironmentFile = cfg.environmentFile;

        LimitNOFILE = 65536;

        DynamicUser = true;
        UMask = "0077";
      };
    };
  };
}


