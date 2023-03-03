{ self, ... }: _:
with self.nixosModules;
{
  platform.system = "x86_64-linux";
  modules = [ bootstrap ];
}
