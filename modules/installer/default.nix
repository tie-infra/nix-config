{ self, nixpkgs, ... }: lib:
{ pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    self.nixosModules.nix-flakes
    self.nixosModules.openssh
  ];

  networking.hostName = "installer";

  services.openssh.hostKeys = [{
    path = "/etc/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  users.users.nixos.openssh.authorizedKeys.keys = lib.sshAuthorizedKeys;

  isoImage = {
    # NixOS uses syslinux for legacy BIOS boot, and syslinux currently cannot be
    # cross-compiled from non-x86 platforms. As a workaround, we disable legacy
    # BIOS boot (note that USB boot is subset of BIOS boot).
    makeBiosBootable = nixpkgs.lib.mkForce false;
    makeUsbBootable = nixpkgs.lib.mkForce false;
    makeEfiBootable = nixpkgs.lib.mkForce true;

    # TODO: move to system packages.
    contents = [
      {
        source = ./bootstrap.sh;
        target = "bootstrap.sh";
      }
      {
        source = ./sfdisk.dump;
        target = "sfdisk.dump";
      }
    ];
  };
}
