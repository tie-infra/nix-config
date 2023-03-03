_: lib: {
  platform.system = "x86_64-linux";
  modules = [ (lib.import ./configuration.nix) ];
}
