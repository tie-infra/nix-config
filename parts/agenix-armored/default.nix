{
  perSystem = { pkgs, inputs', ... }: {
    packages.agenix-armored = pkgs.applyPatches {
      src = inputs'.agenix.packages.default;
      patches = [ ./armor.patch ];
    };
  };
}
