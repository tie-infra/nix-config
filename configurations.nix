{ nixosWithSystem, ... }:
{
  flake.nixosConfigurations = {
    bootstrap-x86-64 = nixosWithSystem "x86_64-linux" [ ./hosts/bootstrap/configuration.nix ];

    akane = nixosWithSystem "x86_64-linux" [ ./hosts/akane/configuration.nix ];
    brim = nixosWithSystem "x86_64-linux" [
      ./hosts/brim/configuration.nix
      ./hosts/brim/sops.nix
      ./hosts/brim/systemd-socket-proxyd.nix
    ];
    kazuma = nixosWithSystem "x86_64-linux" [ ./hosts/kazuma/configuration.nix ];
    saitama = nixosWithSystem "x86_64-linux" [ ./hosts/saitama/configuration.nix ];
    falcon = nixosWithSystem "x86_64-linux" [ ./hosts/falcon/configuration.nix ];
  };
}
