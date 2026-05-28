{
  lib,
  buildGoModule,
  fetchFromGitHub,
  applyPatches,
  pkgconf,
  libopus,
  libdave,
}:
buildGoModule rec {
  pname = "mumble-discord-bridge";
  version = "0.9.0";

  # https://github.com/Stieneee/mumble-discord-bridge/pull/104
  src = fetchFromGitHub {
    owner = "Stieneee";
    repo = "mumble-discord-bridge";
    tag = "v${version}";
    hash = "sha256-9EFTmRJx7vsjvSX9nbXtpDkgif3IlaGRKxQRxyuJ3hs=";
  };

  nativeBuildInputs = [
    pkgconf
  ];

  buildInputs = [
    libopus
    (libdave.overrideAttrs (oldAttrs: {
      # Workaround for https://github.com/disgoorg/godave
      postInstall = oldAttrs.postInstall or "" + ''
        ln -s -T -- dave/dave.h "$out"/include/dave.h
      '';
    }))
  ];

  vendorHash = "sha256-vUr0Im1UrJHPhGcAk6z1KYVj+dEhADbP4ZJtVgNaQk8=";

  meta = {
    description = "A simple voice bridge between Mumble and Discord.";
    homepage = "https://github.com/Stieneee/mumble-discord-bridge";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.tie ];
    mainProgram = "mumble-discord-bridge";
  };
}
