{ config, ... }: {
  systemd.services.systemd-networkd = {
    environment.SYSTEMD_LOG_LEVEL = "debug";
  };
}
