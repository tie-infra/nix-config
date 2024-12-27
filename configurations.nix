{ inputs, nixosWithSystem, ... }:
{
  flake.nixosConfigurations = {
    bootstrap-x86-64 = nixosWithSystem "x86_64-linux" [ ./hosts/bootstrap/configuration.nix ];
    akane = nixosWithSystem "x86_64-linux" [
      ./hosts/akane/configuration.nix
      inputs.amneziawg.nixosModules.nixos-2411
    ];
    brim = nixosWithSystem "x86_64-linux" [ ./hosts/brim/configuration.nix ];
    kazuma = nixosWithSystem "x86_64-linux" [ ./hosts/kazuma/configuration.nix ];
    saitama = nixosWithSystem "x86_64-linux" [ ./hosts/saitama/configuration.nix ];
    falcon = nixosWithSystem "x86_64-linux" [
      ./hosts/falcon/configuration.nix
      inputs.amneziawg.nixosModules.nixos-2411
    ];
  };
}
