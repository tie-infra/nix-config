{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    # See also https://github.com/yaxitech/ragenix
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, deploy-rs, agenix }: {
    nixosModules = { dibbler-client = import ./modules/dibbler-client.nix; };

    nixosConfigurations.bootstrap-amd64 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/bootstrap/configuration.nix ];
    };

    nixosConfigurations.saitama = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules =
        [ self.nixosModules.dibbler-client ./hosts/saitama/configuration.nix ];
    };

    deploy.nodes.saitama = {
      hostname = "saitama.b1nary.tk";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.saitama;
      };
    };

    deploy.sshUser = "nixos";
    deploy.sshOpts = let f = ./known_hosts;
    in [ "-o" "CheckHostIP=no" "-o" "UserKnownHostsFile=${f}" ];

    defaultPackage.x86_64-linux =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.linkFarm "infra" [{
        name = "bootstrap";
        path = pkgs.symlinkJoin {
          name = "bootstrap";
          paths = [
            # TODO(tie): add arm64 bootstrap image
            self.nixosConfigurations.bootstrap-amd64.config.system.build.isoImage
          ];
        };
      }];

    devShell.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = [ deploy-rs.defaultPackage.x86_64-linux ];
    };

    checks =
      builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy)
      deploy-rs.lib;
  };
}
