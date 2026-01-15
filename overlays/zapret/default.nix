final: prev: {
  zapret = prev.zapret.overrideAttrs (oldAttrs: rec {
    strictDeps = true;
    buildInputs = oldAttrs.buildInputs or [ ] ++ [ final.systemdLibs ];
    buildFlags = [ "systemd" ]; # make target
  });
}
