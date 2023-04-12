{ self, nixpkgs, agenix, ... }: lib:
{ modulesPath, ... }: {
  imports = with self.nixosModules; [
    (lib.import ./boot.nix)
    (lib.import ./pufferpanel.nix)
    erase-your-darlings
    systemd-boot
    nix-flakes
    persist-machineid
    openssh
    persist-ssh
    trust-admins
    agenix.nixosModules.default
  ];

  hardware.enableRedistributableFirmware = true;
  zramSwap.enable = true;

  system.stateVersion = "22.11";
  networking.hostName = "kazuma";
  time.timeZone = "Europe/Moscow";

  services.netdata.enable = true;
  networking.firewall.allowedUDPPorts = [ 3000 ];
  networking.firewall.allowedTCPPorts = [ 3001 19999 25565 25569 ];
  networking.firewall.logRefusedConnections = false;

  environment.systemPackages = [ pkgs.htop pkgs.btop pkgs.file ];

  users = {
    mutableUsers = false;
    users.nixos = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];

      openssh.authorizedKeys.keys = lib.sshAuthorizedKeys;
    };
  };
}
