final: prev: {
  zapret = prev.zapret.overrideAttrs (oldAttrs: rec {
    version = "70.6";
    src = final.fetchFromGitHub {
      owner = "bol-van";
      repo = "zapret";
      rev = "6b0bc7a96b232f1f2db5aafea474ec1503b28207";
      hash = "sha256-J7gQ4g9oVhOZAtIXv46u9dKTuaAL9FUPBbqCRAfyKWk=";
    };
    #patches = oldAttrs.patches or [ ] ++ [ ./desync.patch ];
    strictDeps = true;
    buildInputs = oldAttrs.buildInputs or [ ] ++ [ final.systemdLibs ];
    buildFlags = [ "systemd" ]; # make target
  });
}
