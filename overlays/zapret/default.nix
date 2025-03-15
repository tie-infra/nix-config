final: prev: {
  zapret = prev.zapret.overrideAttrs (oldAttrs: {
    version = "unstable-2025-03-14";
    src = final.fetchFromGitHub {
      owner = "bol-van";
      repo = "zapret";
      rev = "94d4238af2ed272248b695b44a8851be456855a2";
      hash = "sha256-Jlcq3jX4h8DBrerNVZm8SWRepMacEbk2D+pNO/Zo1OE=";
    };
    strictDeps = true;
    buildInputs = oldAttrs.buildInputs or [ ] ++ [ final.systemdLibs ];
    buildFlags = [ "systemd" ]; # make target
  });
}
