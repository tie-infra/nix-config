{ self, nixpkgs, ... }:
lib:
system:
with nixpkgs.legacyPackages.${system};
with self.packages.${system};
{
  direnv = lib.mkMinimalShell system {
    packages = [
      nixpkgs-fmt
      agenix-armored
    ];
  };
}
