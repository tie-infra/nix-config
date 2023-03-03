_: _: {
  nix.settings.trusted-users = [ "@wheel" ];
  security.sudo.wheelNeedsPassword = false;
}
