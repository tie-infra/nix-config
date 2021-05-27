{ config, lib, pkgs, modulesPath, ... }: {
  imports = [
    ../../profiles/nix-flakes.nix
    ../../profiles/avahi-mdns.nix
    ../../profiles/openssh.nix
    ../../profiles/networkd-debug.nix
    ./boot.nix
    ./networking.nix
    ./persist-ssh.nix
  ];

  system.stateVersion = "20.09";

  time.timeZone = "Europe/Moscow";

  nix = {
    # Trust all admins.
    trustedUsers = [ "@wheel" ];
    # Remove generations older than one weeks.
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  users = {
    mutableUsers = false;
    users.nixos = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPSTOhvWnmozjnk82eW9yzb7Flty48PwsNTF+KItdv5w actions-user@github.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAKU7x1o6NPI/7AqwCaC8edvl80//2LgyVSV/3tIfb tie@xhyve"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFOq52CJ77uZJ7lDpRgODDMaO22PeHi1GB+rRyj7j+o1 tie@goro"
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  services.zfs.autoSnapshot.enable = true;
  services.zfs.autoScrub.enable = true;

  # FIXME: that would fail on reinstall.
  environment.etc."machine-id".source = "/persist/machine-id";
}
