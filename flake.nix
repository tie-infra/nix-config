{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-20.09";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    # See also https://github.com/yaxitech/ragenix
  };

  outputs = { self, nixpkgs, deploy-rs, agenix }: {
    nixosConfigurations.bootstrap = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
        ./modules/profiles/nix-flakes.nix
        ./modules/profiles/avahi-mdns.nix
        ./modules/profiles/openssh.nix
        ./hosts/bootstrap/configuration.nix
      ];
    };

    defaultPackage.x86_64-linux =
      self.nixosConfigurations.bootstrap.config.system.build.isoImage;
  };
}
