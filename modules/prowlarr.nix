{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.prowlarr;
in
{
  options.services.prowlarr = {
    enable = lib.mkEnableOption "Prowlarr";
    package = lib.mkPackageOption pkgs "prowlarr" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.prowlarr = {
      description = "Prowlarr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
        Restart = "always";

        ExecStart = "${lib.getExe' cfg.package "Prowlarr"} --nobrowser --data=\${STATE_DIRECTORY}/data";

        DynamicUser = true;

        StateDirectory = "prowlarr";
        StateDirectoryMode = "0750"; # u=rwx,g=rx,o=

        UMask = "0027"; # u=rwx,g=rx,o=
      };
    };
  };
}
