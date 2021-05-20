{ config, lib, pkgs, ... }: {
  isoImage.isoName = lib.mkForce "nixos-bootstrap.iso";

  networking.hostName = "bootstrap";

  # Enable flakes.
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Enable mDNS discovery.
  services.avahi.enable = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.addresses = true;

  # Enable SSH access.
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;
  services.openssh.hostKeys = [{
    path = "/etc/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];
  services.openssh.passwordAuthentication = false;
  services.openssh.challengeResponseAuthentication = false;
  services.openssh.extraConfig = ''
    LoginGraceTime 15s
    RekeyLimit default 30m
    HostKeyAlgorithms ssh-ed25519
  '';

  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAKU7x1o6NPI/7AqwCaC8edvl80//2LgyVSV/3tIfb tie@xhyve"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFOq52CJ77uZJ7lDpRgODDMaO22PeHi1GB+rRyj7j+o1 tie@goro"
  ];
}
