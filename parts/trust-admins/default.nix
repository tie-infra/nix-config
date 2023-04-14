{
  flake.nixosModules.trust-admins = {
    nix.settings.trusted-users = [ "@wheel" ];
    security.sudo.wheelNeedsPassword = false;
  };
}
