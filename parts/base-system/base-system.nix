{ self, inputs, ... }:
{ lib, pkgs, config, ... }: {
  imports = [
    self.nixosModules.nix-flakes
    self.nixosModules.services
    self.nixosModules.machine-info
  ];

  nixpkgs.overlays = [ inputs.btrfs-rollback.overlays.default ];

  environment.systemPackages = with pkgs; [
    ripgrep
    fd
    file
    tree
    htop
    btop
    vim
    rcon
    mc
  ];

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  zramSwap.enable = true;

  networking = {
    useNetworkd = true;

    # Disables DHCP on `en*` and `eth*` interfaces.
    # See https://github.com/NixOS/nixpkgs/blob/2920b6fc16a9ed5d51429e94238b28306ceda79e/nixos/modules/tasks/network-interfaces-systemd.nix#L49-L56
    #
    # We enable DHCP in installer and bootstrap systems, but otherwise network
    # configuration is host-specific.
    useDHCP = lib.mkDefault false;

    firewall.logRefusedConnections = lib.mkDefault false;
  };

  security.polkit.enable = true;

  users = {
    mutableUsers = false;
    users.nixos = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = with config.users.groups;
        [ wheel.name disk.name ];
      openssh.authorizedKeys.keys = with self.lib.sshKeys;
        github-actions ++ tie ++ brim;
    };
  };

  services = {
    getty.autologinUser = config.users.users.nixos.name;

    resolved.enable = true;

    openssh = {
      enable = true;
      startWhenNeeded = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      extraConfig = ''
        LoginGraceTime 15s
        RekeyLimit default 30m
      '';
    };
  };
}
