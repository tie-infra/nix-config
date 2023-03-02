{ self, ... }:
lib:
system:
with self.packages.${system};
{
  direnv = lib.mkMinimalShell system {
    packages = [
      agenix-armored
    ];
  };
}
