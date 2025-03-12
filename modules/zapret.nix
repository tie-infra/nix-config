{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    concatMap
    drop
    filter
    literalExpression
    makeBinPath
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    optionals
    types
    ;
  inherit (lib.types)
    attrsOf
    bool
    enum
    int
    listOf
    nullOr
    oneOf
    package
    port
    str
    submodule
    submoduleWith
    ;
  inherit (lib.cli)
    toGNUCommandLine
    ;

  argType = nullOr (oneOf [
    bool
    int
    str
    (listOf str)
  ]);

  canExecute = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;

  generateConfigFile =
    name: configArgs:
    pkgs.callPackage (
      { runCommand, python3 }:
      runCommand name
        {
          inherit configArgs;
          __structuredAttrs = true;
          nativeBuildInputs = [ python3 ];
          pythonScript = ''
            import pathlib
            import shlex
            import sys

            out = sys.argv[1]
            config = shlex.join(sys.argv[2:])

            out_path = pathlib.Path(out)
            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_text(config)
          '';
        }
        ''
          python3 -c "$pythonScript" "$out" "''${configArgs[@]}"
        ''
    ) { };

  profileModule =
    { config, name, ... }:
    {
      options.enable = mkOption {
        type = bool;
        default = true;
        description = ''
          Whether to enable this desync profile.
        '';
      };
      options.settings = mkOption {
        type = submodule { freeformType = attrsOf argType; };
        default = { };
        description = ''
          Declarative DPI desync profile configuration for ${config.programName} service.

          For more details, see
          <https://github.com/bol-van/zapret/blob/master/docs/readme.en.md#${config.programName}>
        '';
      };
      options.args = mkOption {
        type = listOf str;
        internal = true;
        readOnly = true;
      };
      config.args = [
        "--new"
        "--comment=${name}"
      ] ++ toGNUCommandLine { } config.settings;
    };

  instanceModule =
    { config, name, ... }:
    {
      options.enable = mkEnableOption "${config.programName} service";
      options.programName = mkOption {
        type = enum [
          "nfqws"
          "tpws"
        ];
        internal = true;
        readOnly = true;
      };
      options.serviceName = mkOption {
        type = str;
        default = if name != "" then "${config.programName}-${name}" else config.programName;
        defaultText = literalExpression ''
          if name != "" then
            "${config.programName}-''${name}"
          else
            "${config.programName}"
        '';
        description = ''
          Instance’s systemd service name.
        '';
      };
      options.check = mkOption {
        type = bool;
        default = canExecute;
        defaultText = literalExpression ''
          stdenv.buildPlatform.canExecute stdenv.hostPlatform
        '';
        description = ''
          Whether to check the configuration with --dry-run flag at build time.
        '';
      };
      options.settings = mkOption {
        type = submodule { freeformType = attrsOf argType; };
        default = { };
        description = ''
          Declarative configuration for ${config.programName} service.

          For more details, see
          <https://github.com/bol-van/zapret/blob/master/docs/readme.en.md#${config.programName}>
        '';
      };
      options.profiles = mkOption {
        type = attrsOf (submodule profileModule);
        default = { };
        description = ''
          DPI desync profiles.
        '';
      };
      options.configFile = mkOption {
        type = package;
        internal = true;
        readOnly = true;
      };
      config.configFile =
        let
          desyncArgs = concatMap (x: optionals x.enable x.args) (attrValues config.profiles);
          args =
            toGNUCommandLine { } config.settings
            # Initial profile is implicit so remove first --new flag.
            ++ drop 1 desyncArgs;
        in
        generateConfigFile "${config.serviceName}.config" args;
    };

  nfqwsInstanceModule = {
    config.programName = "nfqws";
    options.settings = mkOption {
      type = submodule {
        options.qnum = mkOption {
          type = port;
          description = ''
            Netfilter queue number.
          '';
        };
      };
    };
    options.profiles = mkOption {
      type = attrsOf (submodule {
        options.settings = mkOption {
          example = {
            dpi-desync = "fake";
            dpi-desync-ttl = 1;
            hostlist-auto = "hosts.txt";
          };
        };
      });
      example = {
        "50-https".settings = {
          filter-l7 = "tls,quic";
          dpi-desync = "fake";
          dpi-desync-ttl = 4;
          hostlist-auto = "hosts.txt";
          hostlist-auto-fail-threshold = 1;
        };
        "99-known".settings = {
          dpi-desync = "fakeknown";
          dpi-desync-ttl = 4;
          dpi-desync-repeats = 6;
        };
      };
    };
  };

  tpwsInstanceModule = {
    config.programName = "tpws";
    options.settings = mkOption {
      type = submodule {
        options.port = mkOption {
          type = port;
          description = ''
            TCP port for transparent proxy.
          '';
        };
      };
    };
  };
in
{
  options.services.zapret = {
    package = mkPackageOption pkgs "zapret" { };
    nfqws = mkOption {
      type = attrsOf (submoduleWith {
        modules = [
          instanceModule
          nfqwsInstanceModule
        ];
      });
      default = { };
      description = ''
        nfqs service instances to run.
      '';
    };
    tpws = mkOption {
      type = attrsOf (submoduleWith {
        modules = [
          instanceModule
          tpwsInstanceModule
        ];
      });
      default = { };
      description = ''
        tpws service instances to run.
      '';
    };
  };

  config =
    let
      cfg = config.services.zapret;

      instances = filter (x: x.enable) (
        concatMap attrValues [
          cfg.nfqws
          cfg.tpws
        ]
      );

      systemChecks =
        config:
        let
          inherit (config) configFile;
          dryRun =
            pkgs.runCommand "${config.serviceName}-check-config"
              {
                nativeBuildInputs = [ cfg.package ];
                configFile = configFile.overrideAttrs (oldAttrs: {
                  configArgs = [ "--dry-run" ] ++ oldAttrs.configArgs;
                });
              }
              ''
                ${config.programName} @"$configFile"
                mkdir -p "$out"
              '';
        in
        mkIf config.check [ dryRun ];

      systemdService =
        config:
        let
          inherit (config)
            programName
            serviceName
            configFile
            ;
        in
        {
          ${serviceName} = {
            description = "DPI bypass service - ${serviceName}";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            environment.CONFIG_FILE = configFile;
            serviceConfig = {
              Type = "notify";
              Restart = "on-failure";

              ExecSearchPath = makeBinPath [ cfg.package ];
              ExecStart = "${programName} @\${CONFIG_FILE}";

              StateDirectory = serviceName;
              StateDirectoryMode = "0700";
              WorkingDirectory = "%S/${serviceName}";

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
                "~@resources @privileged"
              ];
            };
          };
        };
    in
    mkIf (instances != [ ]) {
      system.checks = mkMerge (map systemChecks instances);
      systemd.services = mkMerge (map systemdService instances);
    };
}
