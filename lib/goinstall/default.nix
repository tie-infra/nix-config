{ self, nixpkgs, ... }:
lib:
system:
let
  inherit (self.packages.${system}) go;
  inherit (nixpkgs.legacyPackages.${system}) bash cacert;
in
{ name ? "${nixpkgs.lib.replaceStrings ["."] ["-"] modulePath}-${version}"
, # modulePath is the name of the module to download (as in go.mod `module`
  # directive).
  modulePath
, # version is the module version to download (e.g. "v1.0.0").
  version
, # patterns is a list of package import path patterns to install (e.g. "..." to
  # install all packages).
  patterns ? [ "..." ]
, # downloadEnv is an attribute set of environment variables to pass to go
  # install -n.
  downloadEnv ? { }
, # downloadFlags is a list of additional flags to pass to go install -n.
  downloadFlags ? [ ]
, # downloadHash is the hash of the GOMODCACHE directory (with sumdb metadata
  # removed).
  downloadHash
, # installEnv is an attribute set of environment variables to pass to go
  # install. The common use case is cross-compiling for GOOS and GOARCH.
  installEnv ? { }
, # installFlags is a list of additional flags to pass to go install.
  installFlags ? [ ]
}:
let
  builder = builtins.derivation {
    inherit system;
    name = "goinstall";
    builder = "${bash}/bin/bash";
    args = [ ./bootstrap.sh "${go}/bin/go" ./builder ];
    outputs = [ "out" ];
    allowedReferences = [ go ];
  };

  toGoFlag = x: "-goflag=${x}";
  toGoEnv = x: "-goenv=${x}";
  attrsToEnv = attrs: nixpkgs.lib.mapAttrsToList (name: value: "${name}=${value}") attrs;

  drvName = nixpkgs.lib.strings.sanitizeDerivationName name;
  packages =
    if builtins.length patterns > 0
    then nixpkgs.lib.forEach patterns (pattern: "${modulePath}/${pattern}@${version}")
    else [ "${modulePath}@${version}" ];

  modCache = builtins.derivation {
    inherit system builder;
    name = "${drvName}-modcache";
    args = [ "download" "-cadir=${cacert}/etc/ssl/certs" ]
      ++ (nixpkgs.lib.forEach downloadFlags toGoFlag)
      ++ (nixpkgs.lib.forEach (attrsToEnv downloadEnv) toGoEnv)
      ++ [ "--" ] ++ packages;
    outputs = [ "out" ];
    outputHash = downloadHash;
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    allowedReferences = [ ];
  };
in
builtins.derivation {
  inherit system builder;
  name = drvName;
  args = [ "install" "-modcache=${modCache}" ]
    ++ (nixpkgs.lib.forEach installFlags toGoFlag)
    ++ (nixpkgs.lib.forEach (attrsToEnv installEnv) toGoEnv)
    ++ [ "--" ] ++ packages;
  outputs = [ "out" ];
  allowedReferences = [ ];
}
