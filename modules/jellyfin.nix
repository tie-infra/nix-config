{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.jellyfin;
in
{
  options.services.jellyfin = {
    enable = lib.mkEnableOption (lib.mdDoc "Jellyfin Media Server");
    package = lib.mkPackageOptionMD pkgs "jellyfin" { };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = lib.mdDoc ''
        Additional groups under which Jellyfin runs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.jellyfin = {
      description = "Jellyfin Media Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
        Restart = "always";

        ExecStart = ''
          ${lib.getExe' cfg.package "jellyfin"} \
            --datadir ''${STATE_DIRECTORY} \
            --cachedir ''${CACHE_DIRECTORY} \
            --logdir ''${LOGS_DIRECTORY}
        '';

        TimeoutSec = 15;
        SuccessExitStatus = [
          "0"
          "143"
        ];

        DynamicUser = true;
        SupplementaryGroups = cfg.extraGroups;

        StateDirectory = "jellyfin";
        StateDirectoryMode = "0700";
        CacheDirectory = "jellyfin";
        CacheDirectoryMode = "0700";
        LogsDirectory = "jellyfin";
        LogsDirectoryMode = "0700";

        Environment = [
          "XDG_CACHE_HOME=%C/jellyfin/xdg" # for ffmpeg
        ];

        UMask = "0077"; # u=rwx,g=,o=

        NoNewPrivileges = true;
        # AF_NETLINK needed because Jellyfin monitors the network connection
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        LockPersonality = true;
        PrivateTmp = true;
        PrivateDevices = false; # for hardware acceleration
        PrivateUsers = true;
        RemoveIPC = true;

        SystemCallFilter = [
          "~@clock"
          "~@aio"
          "~@chown"
          "~@cpu-emulation"
          "~@debug"
          "~@keyring"
          "~@memlock"
          "~@module"
          "~@mount"
          "~@obsolete"
          "~@privileged"
          "~@raw-io"
          "~@reboot"
          "~@setuid"
          "~@swap"
        ];
        SystemCallErrorNumber = "EPERM";
        SystemCallArchitectures = "native";
      };
    };
  };
}
