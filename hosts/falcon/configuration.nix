{
  config,
  pkgs,
  ...
}:
{
  system.stateVersion = "24.05";

  time.timeZone = "Europe/Moscow";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    initrd.availableKernelModules = [ "nvme" ];
  };

  environment.machineInfo = {
    chassis = "server";
    location = "Falkenstein";
  };

  networking.hostName = "falcon";
}
