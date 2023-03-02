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

    /* Builds a derivation using go install (instead of go build like nixpkgs
       does).

       Type:
         installGoModule :: String -> AttrSet -> Derivation

       Example:
         installGoModule pkgs.system {
           modulePath = "go.pact.im/x/goupdate";
           version = "v0.0.5";
           downloadHash = "sha256-RR74b+bdb805Xs2i1vzKrSdkjyHkHLhGU9Axm14Yi58=";
         }
    */
    installGoModule = system: self.import ./goinstall system;

    /* Returns the autoconf target triple for the given Nix system.

       Type:
         systemToTriple :: String -> AttrSet
    */
    systemToTriple = system:
      let
        systems = {
          "x86_64-linux" = "x86_64-unknown-linux-gnu";
          "aarch64-linux" = "aarch64-unknown-linux-gnu";
        };
      in
      assert lib.assertOneOf "system" system (lib.attrNames systems);
      systems.${system};

    /* Returns Go platform environment variables for the given Nix system.
       Note that Nix uses system doubles that do not express micro-architecture
       levels and feature sets. For such systems, it returns variables for the
       baseline system feature set. For example, on x86-64 it returns GOAMD64=v1
       and on i686 it would return GO386=softfloat.

       Type:
         systemToGo :: String -> AttrSet
    */
    systemToGo = system:
      let
        systems = {
          # Linux
          "aarch64-linux" = {
            GOOS = "linux";
            GOARCH = "arm64";
          };
          "x86_64-linux" = {
            GOOS = "linux";
            GOARCH = "amd64";
            GOAMD64 = "v1";
          };
          "i686-linux" = {
            GOOS = "linux";
            GOARCH = "386";
            GO386 = "softfloat";
          };
          # Darwin
          "aarch64-darwin" = {
            GOOS = "darwin";
            GOARCH = "arm64";
          };
          "x86_64-darwin" = {
            GOOS = "darwin";
            GOARCH = "amd64";
            GOAMD64 = "v1";
          };
          # Windows
          "x86_64-windows" = {
            GOOS = "windows";
            GOARCH = "amd64";
            GOAMD64 = "v1";
          };
          "i686-windows" = {
            GOOS = "windows";
            GOARCH = "386";
            GO386 = "softfloat";
          };
        };
      in
      assert lib.assertOneOf "system" system (lib.attrNames systems);
      systems.${system};

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

    toShellVarPOSIX = name: value:
      lib.throwIfNot (lib.isValidPosixName name)
        "toShellVarPOSIX: ${name} is not a valid shell variable name"
        "${name}=${lib.escapeShellArg value}";

    toShellVarsPOSIX = vars: lib.concatStringsSep " " (lib.mapAttrsToList self.toShellVarPOSIX vars);

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
