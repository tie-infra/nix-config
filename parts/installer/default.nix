{ inputs, lib, ... }@args:
let
  # Some packages cannot be cross-compiled from macOS.
  mkIfSupported = system:
    let platform = lib.systems.elaborate system;
    in lib.mkIf (!platform.isDarwin);

  installer = inputs.nixpkgs.lib.nixosSystem {
    modules = [ (import ./installer.nix args) ];
  };
  systemFor = { host, build ? host }:
    installer.extendModules {
      modules = [
        ({ lib, ... }: {
          nixpkgs.hostPlatform.system = host;
          nixpkgs.buildPlatform = lib.mkIf (host != build) {
            system = build;
          };
        })
      ];
    };
in
{
  perSystem = { system, ... }: mkIfSupported system {
    packages.installer-x86-64-iso =
      let cfg = systemFor { host = "x86_64-linux"; build = system; };
      in cfg.config.system.build.isoImage;
  };
}
