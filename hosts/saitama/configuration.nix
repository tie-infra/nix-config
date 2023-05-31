{ self, ... }:
{ lib, config, ... }: {
  imports = [
    self.nixosModules.base-system
    self.nixosModules.erase-your-darlings
    self.nixosModules.trust-admins
  ];

  nixpkgs.hostPlatform.system = "x86_64-linux";

  system.stateVersion = "23.05";
  networking.hostName = "saitama";
  time.timeZone = "Europe/Moscow";

  hardware.enableRedistributableFirmware = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  boot.initrd.availableKernelModules = [ "ahci" "amd64_edac" ];

  zramSwap.enable = true;

  eraseYourDarlings =
    let disk = "WDC_WD10EALX-009BA0_WD-WCATR5170643";
    in {
      bootDisk = "/dev/disk/by-id/ata-${disk}-part1";
      rootDisk = "/dev/disk/by-id/ata-${disk}-part2";
    };

  services = {
    netdata.enable = true;
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    # Set user and group to non-default value to avoid creating them.
    # See https://github.com/NixOS/nixpkgs/blob/58bf1f8bad92bea6fa0755926f517ca585f93986/nixos/modules/services/misc/jellyfin.nix#L110-L119
    user = "nobody";
    group = "nobody";
  };
  systemd.services.jellyfin = {
    serviceConfig = {
      DynamicUser = true;
      User = lib.mkForce null;
      Group = lib.mkForce null;
      SupplementaryGroups = with config.users.groups; [
        video.name
        render.name
      ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 19999 ];
  };
}
