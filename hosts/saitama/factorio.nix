{ config, lib, ... }:
let serverSettingsFile = "/run/secrets/factorio-server-settings.age.json";
in {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "factorio-headless" ];

  users.users.factorio = {
    isSystemUser = true;
    group = "factorio";
    home = "/var/lib/factorio";
    createHome = true;
  };
  users.groups.factorio = { };

  age.secrets.factorio-server-settings = {
    file = ./factorio-server-settings.age;
    mode = "0444";
    path = serverSettingsFile;
  };

  systemd.tmpfiles.rules = [
    # mkdir -p
    "d /persist/factorio - - - - -"
    # chmod u=rwx,g=rx,o=
    "z /persist/factorio 0750 - - - -"
  ];
  systemd.mounts = [{
    type = "none";
    options = "bind";
    what = "/persist/factorio";
    where = "/var/lib/factorio";
    requiredBy = [ "factorio.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    unitConfig = {
      RequiresMountsFor = "/persist";
      ConditionPathIsDirectory = "/persist/factorio";
    };
  }];

  services.factorio = {
    enable = true;
    openFirewall = true;
    stateDirName = "factorio";
  };

  # For some reason factorio service doesn’t provide an option to load
  # game password from file. As a workaround we have to override unit
  # definition to pass custom server settings file that contains our
  # password.
  # TODO(tie): what’s the point of using services.factorio if we don’t
  # use any options except openFirewall? Perhaps it’d be cleaner to just
  # copy service definition.
  systemd.services.factorio = {
    preStart = lib.mkForce "";

    serviceConfig = {
      User = "factorio";
      Group = "factorio";
      DynamicUser = lib.mkForce false;

      ExecStart = let cfg = config.services.factorio;
      in lib.mkForce (toString [
        "${cfg.package}/bin/factorio"
        "--config=${cfg.configFile}"
        "--port=${toString cfg.port}"
        "--start-server=/var/lib/${cfg.stateDirName}/saves/${cfg.saveName}.zip"
        "--server-settings=${serverSettingsFile}"
      ]);
    };
  };
}
