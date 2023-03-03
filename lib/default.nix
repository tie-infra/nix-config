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
  };
in
self
