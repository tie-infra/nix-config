{ self, ... }:
{ lib, config, ... }: {
  imports = [
    self.nixosModules.base-system
    self.nixosModules.erase-your-darlings
    self.nixosModules.trust-admins
  ];

  system.stateVersion = "23.05";

  time.timeZone = "Europe/Moscow";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    initrd.availableKernelModules = [ "ahci" "amd64_edac" ];
  };

  eraseYourDarlings =
    let disk = "WDC_WD10EALX-009BA0_WD-WCATR5170643";
    in {
      bootDisk = "/dev/disk/by-id/ata-${disk}-part1";
      rootDisk = "/dev/disk/by-id/ata-${disk}-part2";
    };

  networking = {
    hostName = "saitama";
    firewall = {
      allowedTCPPorts = [ 19999 ];
    };
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
}
