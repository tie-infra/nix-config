{ lib, pkgs, config, ... }:
let
  cfg = config.services.jackett;
in
{
  disabledModules = [ "services/misc/jackett.nix" ];

  options.services.jackett = {
    enable = lib.mkEnableOption (lib.mdDoc "Jackett");
    package = lib.mkPackageOptionMD pkgs "jackett" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.jackett = {
      description = "Jackett";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";

        ExecStart = "${lib.getExe cfg.package} --NoUpdates --DataFolder \${STATE_DIRECTORY}";

        StateDirectory = "jackett";
        StateDirectoryMode = "0700";

        DynamicUser = true;
      };
    };
  };
}
