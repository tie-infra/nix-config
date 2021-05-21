{ config, pkgs, ... }: {
  system.stateVersion = "20.09";

  imports = [
    ./hardware.nix
  ];

  networking.hostName = "nia";
  networking.hostId = "c2e4086f";

  time.timeZone = "Europe/Moscow";

  networking.useDHCP = false;
  networking.interfaces.enp2s0.useDHCP = true;
  networking.interfaces.enp3s0.useDHCP = true;

  users.mutableUsers = false;
  users.users.nixos = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAKU7x1o6NPI/7AqwCaC8edvl80//2LgyVSV/3tIfb tie@xhyve"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFOq52CJ77uZJ7lDpRgODDMaO22PeHi1GB+rRyj7j+o1 tie@goro"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh.hostKeys = [{
    path = "/persist/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];
}
