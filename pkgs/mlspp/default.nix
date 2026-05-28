{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  openssl,
  nlohmann_json,
}:
stdenv.mkDerivation {
  pname = "mlspp";
  version = "0-unstable-2025-11-25";

  src = fetchFromGitHub {
    owner = "cisco";
    repo = "mlspp";
    rev = "61e4d76dbe6628cbe36ffb9cab684f3bee390d05";
    hash = "sha256-V2ptsh7CFW0eN46RdDeCVO++DkFKyRFvwnQqvQ7l6Qs=";
  };

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    openssl
    nlohmann_json
  ];

  meta = {
    homepage = "https://github.com/cisco/mlspp";
    description = "Implementation of Messaging Layer Security";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
    maintainers = [ lib.maintainers.tie ];
  };
}
