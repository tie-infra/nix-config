{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-20.09";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    # See also https://github.com/yaxitech/ragenix
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
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

    nixosConfigurations.nia = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./modules/profiles/nix-flakes.nix
        ./modules/profiles/avahi-mdns.nix
        ./modules/profiles/openssh.nix
        ./hosts/nia/configuration.nix
      ];
    };

    deploy.nodes.nia = {
      hostname = "nia.b1nary.tk";
      profiles.system = {
        sshUser = "nixos";
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nia;
      };
    };

    devShell.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = [
        deploy-rs.defaultPackage.x86_64-linux
      ];
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
