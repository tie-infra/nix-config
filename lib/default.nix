{ nixpkgs, ... }@inputs:
let
  inherit (nixpkgs) lib;
  self = {
    /* A list of systems exposed by our flake.

       Type:
         exposedSystems :: List
    */
    exposedSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    /* A list of SSH authorized keys for system configurations.

       Type:
         sshAuthorizedKeys :: List
    */
    sshAuthorizedKeys = import ./authorized-keys.nix;

    /* Generates attribute set by calling f for each exposed system.

       Type:
         forAllSystems :: (String -> Any) -> AttrSet
    */
    forAllSystems = f: lib.genAttrs self.exposedSystems (system: f system);

    /* Imports the given path and calls the resulting expression with inputs and
       and then lib itself.

       Type:
         import :: Path -> AttrSet

       Examples:
         importSubdirs ./.
    */
    import = path: import path inputs self;

    /* Like import, but imports all subdirectories of the given path. Returns an
       attribute set where names are directory names and values are imported
       directories.

       Type:
         importSubdirs :: Path -> AttrSet

       Examples:
         importSubdirs ./.
    */
    importSubdirs = path:
      lib.mapAttrs (name: _: self.import "${path}/${name}")
        (lib.filterAttrs (name: type: type == "directory") (builtins.readDir path));

    /* Returns a derivation that can be used as a minimal shell for direnv.

       Based on https://github.com/NixOS/nixpkgs/pull/132617 and https://github.com/numtide/devshell
       to reduce clutter that pkgs.mkShell brings into the environment.

       Type:
         mkMinimalShell :: String -> AttrSet -> Derivation

       Example:
         mkMinimalShell pkgs.system {
           packages = [ pkgs.go ];
         }
    */
    mkMinimalShell = system: self.import ./minimal-shell system;

    /* Generate an attribute set by mapping a function that returns a derivation
       over a list of systems. If cross system matches local system, it creates
       an attribute named "default" for the local system.

       Type:
         crossDerivation :: String -> List -> (String -> Derivation) -> AttrSet

       Example:
         system = "aarch64-linux";
         crossSystems = ["aarch64-linux" "x86_64-linux"];
         crossDerivation system crossSystems (crossSystem:
           builtins.derivation ({ inherit system; } // buildArgs)
         )
         => {
           default = «derivation 1»;
           "aarch64-linux" = «derivation 1»;
           "x86_64-linux" = «derivation 2»;
         }
    */
    crossDerivation = localSystem: crossSystems: fdrv:
      let attrs = lib.genAttrs crossSystems (crossSystem: fdrv crossSystem); in
      if attrs ? ${localSystem}
      then attrs // { default = attrs.${localSystem}; }
      else attrs;

    /* Merge an attribute set where values are either derivations or attribute
       sets of cross-derivations (see crossDerivation).

       Type:
       mergePackages :: AttrSet -> AttrSet
    */
    mergePackages = attrs:
      let
        merge = acc: name:
          let value = attrs.${name}; in
          acc // flatten acc name value;
        flatten = acc: name: value:
          if lib.isDerivation value
          then { ${name} = value; }
          else lib.mapAttrs' (prefix acc name) value;
        prefix = acc: name: variant: value:
          let
            accName =
              if variant != "default"
              then "${name}/${variant}"
              else name;
          in
          lib.throwIf (acc ? ${accName}) "Duplicate package: ${accName}"
            (lib.nameValuePair accName value);
      in
      lib.foldl merge { } (lib.attrNames attrs);

    nixpkgsCross = localSystem: crossSystem:
      let
        systems = {
          "x86_64-linux" = "gnu64";
          "aarch64-linux" = "aarch64-multiplatform";
        };
        pkgs = nixpkgs.legacyPackages.${localSystem};
      in
      if localSystem != crossSystem then
        lib.throwIfNot (systems ? ${crossSystem})
          "Unsupported system: ${crossSystem}"
          pkgs.pkgsCross.${systems.${crossSystem}}
      else
        pkgs;
  };
in
self
