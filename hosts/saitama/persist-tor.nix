{ config, ... }:
let path = "/persist/tor";
in {
  systemd.tmpfiles.rules = [
    # mkdir -p
    "d ${path} - - - - -"
    # chmod u=rwx,g=rx,o=
    "z ${path} 0750 - - - -"
  ];
  systemd.mounts = [{
    type = "none";
    options = "bind";
    what = "/persist/tor";
    where = "/var/lib/tor";
    requiredBy = [ "tor.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    unitConfig = {
      RequiresMountsFor = "/persist";
      ConditionPathIsDirectory = "/persist/tor";
    };
  }];
}
