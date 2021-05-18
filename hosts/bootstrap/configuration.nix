{ config, lib, pkgs, ... }: {
  isoImage.isoName = lib.mkForce "nixos-bootstrap.iso";

  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAKU7x1o6NPI/7AqwCaC8edvl80//2LgyVSV/3tIfb tie@xhyve"
  ];
}
