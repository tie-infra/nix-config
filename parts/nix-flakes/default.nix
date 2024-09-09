{ inputs, ... }:
{
  flake.nixosModules.nix-flakes =
    { pkgs, ... }:
    {
      nix = {
        package = pkgs.nixFlakes;
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          use-xdg-base-directories = true;
          warn-dirty = false;
        };

        channel.enable = false;

        # See https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
        registry.nixpkgs.flake = inputs.nixpkgs;
      };
    };
}
