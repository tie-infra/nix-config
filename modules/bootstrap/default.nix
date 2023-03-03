{ self, nixpkgs, ... }: _:
{ modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    self.nixosModules.nix-flakes
    self.nixosModules.openssh
  ];

  networking.hostName = "bootstrap";

  services.openssh.hostKeys = [{
    path = "/etc/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAKU7x1o6NPI/7AqwCaC8edvl80//2LgyVSV/3tIfb tie@xhyve"
  ];

  # NixOS uses syslinux for legacy BIOS boot, and syslinux currently cannot be
  # cross-compiled from non-x86 platforms. As a workaround, we disable legacy
  # BIOS boot (note that USB boot is subset of BIOS boot).
  isoImage = {
    makeBiosBootable = nixpkgs.lib.mkForce false;
    makeUsbBootable = nixpkgs.lib.mkForce false;
    makeEfiBootable = nixpkgs.lib.mkForce true;
  };
}
