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
  version = "0-unstable-2026-04-13";

  src = fetchFromGitHub {
    owner = "cisco";
    repo = "mlspp";
    rev = "92aaa4134fa45ec39957a7c81a342401fba7feb2";
    hash = "sha256-HElw0fvL7ClDSXBDYRw1qcPw73oWvbMfi7skQokyftY=";
  };

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    openssl
    nlohmann_json
  ];

  env.NIX_CFLAGS_COMPILE = "-Wno-error=maybe-uninitialized";

  meta = {
    homepage = "https://github.com/cisco/mlspp";
    description = "Implementation of Messaging Layer Security";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
    maintainers = [ lib.maintainers.tie ];
  };
}
