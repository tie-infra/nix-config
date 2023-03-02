{ nixpkgs, ... }@inputs:
lib:
system:
let pkgs = nixpkgs.legacyPackages.${system}; in
{ name ? "shell"
, # A list of packages to add to the PATH environment variable.
  packages
}:
builtins.derivation {
  inherit system name;

  builder = pkgs.stdenv.shell;
  args = [ "-c" "export >$out" ];
  outputs = [ "out" ];

  stdenv = pkgs.writeTextFile {
    name = "setup";
    executable = true;
    destination = "/setup";
    text = ''
      export -n outputs out
      export -n builder name stdenv system
      export -n dontAddDisableDepTrack
      export -n NIX_BUILD_CORES NIX_STORE
      PATH=${nixpkgs.lib.makeBinPath packages}
    '';
  };
}
