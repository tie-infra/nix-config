{
  config,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  system.stateVersion = "23.11";

  time.timeZone = "Europe/Moscow";

  boot.loader.grub = {
    enable = true;
    configurationLimit = 10;
    device = "/dev/disk/by-path/virtio-pci-0000:00:07.0";
  };

  eraseYourDarlings = {
    bootDisk = "/dev/disk/by-uuid/2C36-A9EE";
    rootDisk = "/dev/disk/by-uuid/d953273d-8717-4eed-9db8-0e0c16749784";
  };

  environment.machineInfo = {
    location = "Helsinki VDS from aeza.net";
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    traceroute
    tcpdump
    iperf3
  ];

  networking.hostName = "helsing";

  services = {
    netdata.enable = true;
    qemuGuest.enable = true;
  };

  # Instead of using credentials directory that is not documented, just give
  # systemd-networkd permission to access secrets.
  # See also https://github.com/systemd/systemd/issues/26702
  systemd.services.systemd-networkd = {
    serviceConfig = {
      SupplementaryGroups = [ config.users.groups.keys.name ];
    };
  };

  sops = {
    secrets = {
      "wireguard/pk.txt" = {
        mode = "0440";
        group = config.users.groups.systemd-network.name;
        reloadUnits = [ "systemd-networkd.service" ];
        sopsFile = ./secrets.yaml;
      };
      "wireguard/psk.txt" = {
        mode = "0440";
        group = config.users.groups.systemd-network.name;
        reloadUnits = [ "systemd-networkd.service" ];
      };
    };
  };
}
