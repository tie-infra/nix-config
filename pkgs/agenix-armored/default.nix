{ agenix, ... }:
lib:
system:
agenix.packages.${system}.default.overrideAttrs (_: {
  installPhase = ''
    install -D $src $out/bin/agenix
    patch $out/bin/agenix ${./armor.patch}
  '';
})
