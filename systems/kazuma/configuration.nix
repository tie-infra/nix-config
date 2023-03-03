{ self, nixpkgs, ... }: lib:
{ modulesPath, ... }: {
  imports = with self.nixosModules; [
    (lib.import ./boot.nix)
    (lib.import ./ssh.nix)
    nix-flakes
    persist-machineid
    trust-admins
  ];

  system.stateVersion = "22.11";
  networking.hostName = "kazuma";
  time.timeZone = "Europe/Moscow";

  users = {
    mutableUsers = false;
    users.nixos = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
}
