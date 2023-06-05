{ lib, pkgs, config, ... }:
let
  cfg = config.services.jackett;

  settingsFormat = pkgs.formats.json { };
  settingsFile = settingsFormat.generate "settings.json" cfg.settings;
in
{
  disabledModules = [ "services/misc/jackett.nix" ];

  options.services.jackett = {
    enable = lib.mkEnableOption (lib.mdDoc "Jackett");
    package = lib.mkPackageOptionMD pkgs "jackett" { };

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
      example = "/run/secrets/jackett/settings.json";
      description = lib.mdDoc ''
        Path to a JSON file to be merged with the settings.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.jackett = {
      description = "Jackett";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";

        LoadCredential =
          lib.optional (cfg.settingsFile != null) "settings.json:${cfg.settingsFile}";

        ExecStartPre = pkgs.writeShellScript "jacket-setup" ''
          set -eux

          cd "$STATE_DIRECTORY"

          configState=ServerConfig.json
          if ! [ -e $configState ]; then
            configState=
          fi

          config="$(${lib.getExe pkgs.jq} --slurp add $configState ${settingsFile} \
            ${lib.optionalString (cfg.settingsFile != null) "\"$CREDENTIALS_DIRECTORY\"/settings.json"})"
          echo -n "$config" >ServerConfig.json
        '';

        ExecStart = "${lib.getExe cfg.package} --NoUpdates --DataFolder \${STATE_DIRECTORY}";

        StateDirectory = "jackett";
        StateDirectoryMode = "0700";

        DynamicUser = true;
      };
    };
  };
}
