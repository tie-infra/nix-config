{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  openssl,
  nlohmann_json,
  mlspp,
  copyPkgconfigItems,
  makePkgconfigItem,
}:
stdenv.mkDerivation rec {
  pname = "libdave";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "discord";
    repo = "libdave";
    tag = "v${version}/cpp";
    hash = "sha256-ALDmtAjSkjnLDcmtpvcwiN7dPvpOgOTNFolr/H3SqsE=";
  };

  sourceRoot = "${src.name}/cpp";

  nativeBuildInputs = [
    cmake
    copyPkgconfigItems
  ];

  pkgconfigItems = [
    (makePkgconfigItem {
      name = "dave";
      version = "1";
      cflags = [ "-I\${includedir}" ];
      libs = [
        "-L\${libdir}"
        "-ldave"
      ];
      variables = {
        includedir = "@includedir@";
        libdir = "@libdir@";
      };
    })
  ];

  env = {
    # copyPkgconfigItems will substitute these in the pkg-config file
    includedir = "${placeholder "out"}/include";
    libdir = "${placeholder "out"}/lib";
  };

  buildInputs = [
    openssl
    nlohmann_json
    (mlspp.overrideAttrs (oldAttrs: {
      cmakeFlags = oldAttrs.cmakeFlags or [ ] ++ [
        (lib.cmakeFeature "MLS_CXX_NAMESPACE" "mlspp")
        (lib.cmakeBool "DISABLE_GREASE" true)
      ];
    }))
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" true)
  ];

  meta = {
    homepage = "https://daveprotocol.com";
    description = "C++ library for Discord's Audio & Video End-to-End Encryption (DAVE) protocol";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    maintainers = [ lib.maintainers.tie ];
  };
}
