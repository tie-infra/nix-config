final: prev: {
  zapret = prev.zapret.overrideAttrs (oldAttrs: {
    version = "unstable-2025-03-12";
    src = final.fetchFromGitHub {
      owner = "bol-van";
      repo = "zapret";
      rev = "9ac73f7d2f07958e33451609c81f241838ef6337";
      hash = "sha256-QnGC5HxLoV/cWkOxFyidl0bVAWHPpaErECqj2ywSo1A=";
    };
    strictDeps = true;
    buildInputs = oldAttrs.buildInputs or [ ] ++ [ final.systemdLibs ];
    buildFlags = [ "systemd" ]; # make target
  });
}
