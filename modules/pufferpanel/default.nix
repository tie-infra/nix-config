{ self, nixpkgs, ... }: _:
{ pkgs, config, ... }:
with nixpkgs.lib; {
  options.services.pufferpanel = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Whether to enable PufferPanel game management server.
      '';
    };

    packages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = "[ pkgs.jre8_headless ]";
      description = ''
        Packages to add to the PATH environment variable.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc ''
        Open ports in the firewall for PufferPanel.
      '';
    };

    bind = mkOption {
      type = types.str;
      default = "";
      example = "[::1]";
      description = ''
        Bind to the specified IP address. Note that IPv6 addresses must be
        enclosed in square brackets.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = ''
        Server listen port.
      '';
    };

    workDir = mkOption {
      type = with types; nullOr path;
      default = null;
      description = mdDoc ''
        Server working directory.
      '';
    };

    logs = mkOption {
      type = with types; nullOr path;
      default = null;
      description = mdDoc ''
        Path to write log files.
      '';
    };

    panel = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to enable PufferPanel web interface.
        '';
      };

      sessionKeyFile = mkOption {
        type = with types; nullOr path;
        default = null;
        description = mdDoc ''
          Path to the session key for cookies.
        '';
      };

      registrationEnabled = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = mdDoc ''
          Whether users can register themselves in the web interface.

          If set via web UI, this option overrides these settings after restart.
        '';
      };

      webFiles = mkOption {
        type = with types; nullOr path;
        default = null;
        example = "/var/www/pufferpanel";
        description = mdDoc ''
          Directory with the frontend files.
        '';
      };

      emailTemplates = mkOption {
        type = with types; nullOr path;
        default = null;
        description = mdDoc ''
          Path to email templates JSON.
        '';
      };

      database = {
        dialect = mkOption {
          type = with types; nullOr str;
          default = null;
          example = "sqlite3";
          description = mdDoc ''
            Database dialect to use.
          '';
        };

        url = mkOption {
          type = with types; nullOr str;
          default = null;
          example = "file:/var/lib/pufferpanel/sqlite.db?cache=shared";
          description = mdDoc ''
            Database URL to connect to.
          '';
        };

        log = mkOption {
          type = with types; nullOr bool;
          default = null;
          description = mdDoc ''
            Enable logging for database queries.
          '';
        };
      };
    };

    daemon = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to enable PufferPanel daemon.
        '';
      };

      console = {
        buffer = mkOption {
          type = with types; nullOr ints.unsigned;
          default = null;
          description = mdDoc ''
            Console buffer size.
          '';
        };

        forward = mkOption {
          type = with types; nullOr bool;
          default = null;
          description = mdDoc ''
            Forward console logs.
          '';
        };
      };

      sftp = {
        bind = mkOption {
          type = types.str;
          default = "";
          example = "[::1]";
          description = mdDoc ''
            Bind to the specified IP address. Note that IPv6 addresses must be
            enclosed in square brackets.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 5657;
          description = mdDoc ''
            Listen port for SFTP server.
          '';
        };

        keyFile = mkOption {
          type = with types; nullOr path;
          default = null;
          description = mdDoc ''
            Path to the private key file for SFTP.
          '';
        };
      };

      auth = {
        url = mkOption {
          type = with types; nullOr str;
          default = null;
          description = mdDoc ''
            Auth server URL.
          '';
        };

        clientId = mkOption {
          type = with types; nullOr str;
          default = null;
          description = mdDoc ''
            OAuth2 client ID.
          '';
        };

        clientSecretFile = mkOption {
          type = with types; nullOr path;
          default = null;
          description = mdDoc ''
            Path to OAuth2 client secret file.
          '';
        };
      };

      data = {
        cache = mkOption {
          type = with types; nullOr path;
          default = null;
          description = mdDoc ''
            Path to cache directory.
          '';
        };

        servers = mkOption {
          type = with types; nullOr path;
          default = null;
          description = mdDoc ''
            Path to servers directory.
          '';
        };

        binaries = mkOption {
          type = with types; nullOr path;
          default = null;
          description = mdDoc ''
            Path to binaries directory.
          '';
        };

        crashLimit = mkOption {
          type = with types; nullOr ints.unsigned;
          default = null;
          description = mdDoc ''
            Crash limit for game servers.
          '';
        };

        maxWSDownloadSize = mkOption {
          type = with types; nullOr ints.unsigned;
          default = null;
          description = mdDoc ''
            Max file size for downloads over WebSocket connection.
          '';
        };
      };
    };

    token = {
      public = mkOption {
        type = with types; nullOr str;
        default = null;
      };
      private = mkOption {
        type = with types; nullOr str;
        default = null;
      };
    };
  };

  config =
    let
      cfg = config.services.pufferpanel;
      workDir =
        if cfg.workDir != null
        then cfg.workDir
        else "/var/lib/pufferpanel";
    in
    mkIf cfg.enable {
      nixpkgs.overlays = [ self.overlays.pufferpanel ];

      systemd.services.pufferpanel = {
        description = "PufferPanel game management panel and daemon.";
        wantedBy = [ "multi-user.target" ];

        path = cfg.packages;

        environment = filterAttrs (_: v: v != null) {
          # Global options.
          PUFFER_WEB_HOST = "${cfg.bind}:${toString cfg.port}";
          PUFFER_LOGS = cfg.logs;

          # Panel options.
          PUFFER_PANEL_ENABLE = boolToString cfg.panel.enable;
          PUFFER_PANEL_DATABASE_DIALECT = cfg.panel.database.dialect;
          PUFFER_PANEL_DATABASE_URL = cfg.panel.database.url;
          PUFFER_PANEL_WEB_FILES = cfg.panel.webFiles;
          PUFFER_PANEL_EMAIL_TEMPLATES = cfg.panel.emailTemplates;
          PUFFER_PANEL_REGISTRATIONENABLED =
            if cfg.panel.registrationEnabled != null
            then boolToString cfg.panel.registrationEnabled
            else null;

          # Daemon options.
          PUFFER_DAEMON_ENABLE = boolToString cfg.daemon.enable;
          PUFFER_DAEMON_CONSOLE_BUFFER = toString cfg.daemon.console.buffer;
          PUFFER_DAEMON_SFTP_HOST = "${cfg.daemon.sftp.bind}:${toString cfg.daemon.sftp.port}";
          PUFFER_DAEMON_SFTP_KEY = cfg.daemon.sftp.keyFile;
          PUFFER_DAEMON_AUTH_URL = cfg.daemon.auth.url;
          PUFFER_DAEMON_AUTH_CLIENTID = cfg.daemon.auth.clientId;
          PUFFER_DAEMON_DATA_CACHE = cfg.daemon.data.cache;
          PUFFER_DAEMON_DATA_SERVERS = cfg.daemon.data.servers;
          PUFFER_DAEMON_DATA_BINARIES = cfg.daemon.data.binaries;
          PUFFER_DAEMON_DATA_CRASHLIMIT = toString cfg.daemon.data.crashLimit;
          PUFFER_DAEMON_DATA_MAXWSDOWNLOADSIZE = toString cfg.daemon.data.maxWSDownloadSize;
          PUFFER_TOKEN_PUBLIC = cfg.token.public;
          PUFFER_TOKEN_PRIVATE = cfg.token.private;
        };

        serviceConfig =
          let
            secrets = filter (x: x.path != null) [
              {
                env = "PUFFER_PANEL_SESSIONKEY";
                id = "sessionkey";
                path = cfg.panel.sessionKeyFile;
              }
              {
                env = "PUFFER_DAEMON_AUTH_CLIENTSECRET";
                id = "clientsecret";
                path = cfg.daemon.auth.clientSecretFile;
              }
            ];
          in
          {
            Type = "simple";
            Restart = "always";

            User = "pufferpanel";
            Group = "pufferpanel";
            StateDirectory = mkIf (cfg.workDir == null) "pufferpanel";
            StateDirectoryMode = mkIf (cfg.workDir == null) "750";

            LoadCredential = map (secret: "${secret.id}:${secret.path}") secrets;

            TimeoutStopSec = "1m";
            CPUQuota = "90%";

            ExecStart = pkgs.writeShellScript "pufferpanel.sh" ''
              ${concatMapStrings (s: s + "\n") (map (secret: ''
                read -r ${secret.env} <"$CREDENTIALS_DIRECTORY"/${secret.id}
                export ${secret.env}
              '') secrets)}
              exec ${pkgs.pufferpanel}/bin/pufferpanel run --workDir ${escapeShellArg workDir}
            '';
            ExecStop = "${pkgs.pufferpanel}/bin/pufferpanel shutdown --pid $MAINPID";
            SendSIGKILL = "no";
          };
      };

      users = {
        users.pufferpanel =
          {
            group = "pufferpanel";
            home = workDir;
            description = "PufferPanel game management server";
            createHome = cfg.workDir != null;
            homeMode = "750";
            isSystemUser = true;
          };
        groups.pufferpanel = { };
      };

      networking.firewall = mkIf cfg.openFirewall {
        allowedTCPPorts = [ cfg.port ] ++ optional cfg.daemon.enable cfg.daemon.sftp.port;
      };
    };
}
