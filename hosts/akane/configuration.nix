{ pkgs, ... }:
{
  system.stateVersion = "23.11";

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };

  boot.initrd.availableKernelModules = [ "ahci" ];

  environment.machineInfo = {
    chassis = "server";
    location = "Ivan’s homelab";
    hardwareVendor = "Qotom";
    hardwareModel = "Q1076GE";
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    traceroute
    tcpdump
    ndisc6
    iperf3
  ];

  profiles.btrfs-erase-your-darlings = {
    enable = true;
    bootDisk = "/dev/disk/by-uuid/7F67-589D";
    rootDisk = "/dev/disk/by-uuid/5b169687-13c2-4357-9cfc-d7ecba357db0";
  };

  networking.hostName = "akane";

  networking.firewall.allowedTCPPorts = [
    # Netdata
    19999
  ];

  services = {
    fstrim.enable = true;
    netdata.enable = true;
  };
}
