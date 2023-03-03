{ self, nixpkgs, ... }: _:
{ modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/all-hardware.nix")
    self.nixosModules.nix-flakes
    self.nixosModules.openssh
    self.nixosModules.erase-your-darlings-btrfs
    self.nixosModules.persist-ssh
    self.nixosModules.persist-machineid
    self.nixosModules.trust-admins
    self.nixosModules.systemd-boot
  ];

  system.stateVersion = nixpkgs.lib.trivial.release;
  networking.hostName = "bootstrap";
  time.timeZone = "Europe/Moscow";

  users = {
    mutableUsers = false;
    users.nixos = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIPgvPYPtXXqGGerR7k+tbrIG2fCzp3R8ox7mkKRIdEu actions@github.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAKU7x1o6NPI/7AqwCaC8edvl80//2LgyVSV/3tIfb tie@xhyve"
      ];
    };
  };

  eraseYourDarlingsBtrfs = {
    rootDisk = "/dev/disk/by-partlabel/nix";
    bootDisk = "/dev/disk/by-partlabel/efi";
  };
}
