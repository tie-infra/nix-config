{ self, ... }: _:
with self.nixosModules;
{
  platform.system = "x86_64-linux";
  # Cross-compilation fails, see pkgs/bootstrap-amd64/default.nix
  buildSystems = [];
  modules = [ bootstrap ];
}
