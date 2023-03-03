{ nixpkgs, ... }:
lib:
let
  nixosSystems = name:
    { platform
    , buildSystems ? lib.exposedSystems
    , modules
    }:
    let
      base = nixpkgs.lib.nixosSystem {
        modules = [{ nixpkgs.hostPlatform = platform; }] ++ modules;
      };
      cross = nixpkgs.lib.mapAttrs' (system: nixpkgs.lib.nameValuePair "${name}/${system}")
        (nixpkgs.lib.genAttrs
          (nixpkgs.lib.remove platform.system buildSystems)
          (system: base.extendModules {
            modules = [{ nixpkgs.buildPlatform.system = system; }];
          }));
    in
    { ${name} = base; } // cross;
in
nixpkgs.lib.concatMapAttrs nixosSystems (lib.importSubdirs ./.)
