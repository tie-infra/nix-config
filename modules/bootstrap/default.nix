{ self, nixpkgs, ... }: lib:
{ modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/all-hardware.nix")
    self.nixosModules.nix-flakes
    self.nixosModules.openssh
    self.nixosModules.erase-your-darlings
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
      openssh.authorizedKeys.keys = lib.sshAuthorizedKeys;
    };
  };

  eraseYourDarlings = {
    bootDisk = "/dev/disk/by-partlabel/efi";
    rootDisk = "/dev/disk/by-partlabel/nix";
  };
}
