{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.outline;
in
{
  options.services.outline = {
    enable = lib.mkEnableOption "Outline";
    package = lib.mkPackageOption pkgs "outline" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.outline = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "exec";
        ExecSearchPath = lib.makeBinPath [ cfg.package ];
        ExecStart = "outline-server";
        WorkingDirectory = "${cfg.package}/share/outline";
        Restart = "always";
        DynamicUser = true;
        UMask = "0007";
        StateDirectory = "outline";
        StateDirectoryMode = "0750";
        RuntimeDirectory = "outline";
        RuntimeDirectoryMode = "0750";
      };
    };
  };
}
