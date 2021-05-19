{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-20.09";
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = { self, nixpkgs, deploy-rs }: {
    nixosConfigurations = {
      bootstrap = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          ./hosts/bootstrap/configuration.nix
        ];
      };
    };

    defaultPackage.x86_64-linux =
      self.nixosConfigurations.bootstrap.config.system.build.isoImage;
  };
}
