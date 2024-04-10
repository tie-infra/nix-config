{
  flake = {
    nixosModules.mcactivity = ./module.nix;
    overlays.mcactivity = import ./overlay.nix;
  };
}
