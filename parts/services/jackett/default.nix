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

        Note that `AdminPassword` field expects as password hash with `APIKey`
        as salt. See [password hashing implementation details] for reference.

        [password hashing implementation details]: https://github.com/Jackett/Jackett/blob/c0a5e24186f76574fdf9fe89bd6e25f1a33ba8d0/src/Jackett.Server/Services/SecurityService.cs#L26-L41
      '';
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--Tracing" ];
      description = lib.mdDoc ''
        Extra flags passed to the Jackett command in the service definition.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.jackett = {
      description = "Jackett";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
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

        ExecStart = ''
          ${lib.getExe' cfg.package "jackett"} --NoUpdates \
            --DataFolder ''${STATE_DIRECTORY} \
            ${lib.escapeShellArgs cfg.extraFlags}
        '';

        StateDirectory = "jackett";
        StateDirectoryMode = "0700";

        DynamicUser = true;
        UMask = "0077";
      };
    };
  };
}
