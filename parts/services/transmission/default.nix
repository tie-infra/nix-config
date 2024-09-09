{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.transmission;
  systemCerts = config.environment.etc."ssl/certs/ca-certificates.crt".source;

  settingsFormat = pkgs.formats.json { };
  settingsFile = settingsFormat.generate "settings.json" cfg.settings;
in
{
  disabledModules = [ "services/torrent/transmission.nix" ];

  options.services.transmission = {
    enable = lib.mkEnableOption (lib.mdDoc "Transmission daemon");
    package = lib.mkPackageOptionMD pkgs "transmission" { };

    cacertBundle = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = lib.mdDoc ''
        File containing trusted certification authorities (CA) to verify
        certificates. If set to `null`, defaults to system trust store.
      '';
    };

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = lib.mdDoc ''
        User account under which Transmission runs. If set to `null`,
        `transmission` user is set up.
      '';
    };

    group = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = lib.mdDoc ''
        Group account under which Transmission runs. If set to `null`,
        `transmission` group is set up.
      '';
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = lib.mdDoc ''
        Additional groups under which Transmission runs.
      '';
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = lib.mdDoc ''
        Settings that overwrite fields in `settings.json` each time the
        service starts.
      '';
    };

    settingsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/secrets/transmission/settings.json";
      description = lib.mdDoc ''
        Path to a JSON file to be merged with the settings.

        Useful to merge a file which is better kept out of the Nix store
        to set secret config parameters like `rpc-password`.
      '';
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--log-debug" ];
      description = lib.mdDoc ''
        Extra flags passed to the transmission command in the service definition.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.transmission = {
      description = "Transmission BitTorrent Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "notify";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";

        LoadCredential =
          lib.optional (cfg.settingsFile != null) "settings.json:${cfg.settingsFile}"
          ++ lib.optional (cfg.cacertBundle != null) "ca-bundle.crt:${cfg.cacertBundle}";

        ExecStartPre = pkgs.writeShellScript "transmission-setup" ''
          set -eu

          cd "$STATE_DIRECTORY"
          mkdir -p config download
          chmod u=rwx,g=,o= config

          configState=config/settings.json
          if ! [ -e $configState ]; then
            configState=
          fi

          config="$(${lib.getExe pkgs.jq} --slurp add $configState ${settingsFile} \
            ${lib.optionalString (cfg.settingsFile != null) "\"$CREDENTIALS_DIRECTORY\"/settings.json"})"
          echo -n "$config" >config/settings.json
          chmod u=rw,g=,o= config/settings.json
        '';

        ExecStart = pkgs.writeShellScript "transmission" ''
          export CURL_CA_BUNDLE=${
            if cfg.cacertBundle != null then "\"$CREDENTIALS_DIRECTORY\"/ca-bundle.crt" else systemCerts
          }
          exec ${lib.getExe' cfg.package "transmission-daemon"} --foreground \
            --config-dir "$STATE_DIRECTORY/config" \
            --download-dir "$STATE_DIRECTORY/download" \
            ${lib.escapeShellArgs cfg.extraFlags}
        '';

        User = if cfg.user != null then cfg.user else config.users.users.transmission.name;
        Group = if cfg.group != null then cfg.group else config.users.groups.transmission.name;

        SupplementaryGroups = cfg.extraGroups;

        StateDirectory = "transmission";
        StateDirectoryMode = "0750"; # u=rwx,g=rx,o=

        UMask = "0027"; # u=rwx,g=rx,o=
        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        DeviceAllow = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
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
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;

        SystemCallFilter = [
          "@system-service"
          # Groups in @system-service which do not contain a syscall
          # listed by perf stat -e 'syscalls:sys_enter_*' transmission-daemon -f
          # in tests, and seem likely not necessary for transmission-daemon.
          "~@aio"
          "~@chown"
          "~@keyring"
          "~@memlock"
          "~@resources"
          "~@setuid"
          "~@timer"
          # In the @privileged group, but reached when querying infos through RPC (eg. with stig).
          "quotactl"
        ];
        SystemCallErrorNumber = "EPERM";
        SystemCallArchitectures = "native";
      };
    };

    users = {
      users.transmission = lib.mkIf (cfg.user == null) {
        isSystemUser = true;
        group = if cfg.group != null then cfg.group else config.users.groups.transmission.name;
      };
      groups.transmission = lib.mkIf (cfg.group == null) {
        members = lib.singleton (
          if cfg.user != null then cfg.user else config.users.users.transmission.name
        );
      };
    };
  };
}
