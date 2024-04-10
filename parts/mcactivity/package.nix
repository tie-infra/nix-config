{ lib
, buildNpmPackage
, fetchFromGitHub
}:
buildNpmPackage rec {
  pname = "mcactivity";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "AshtonMemer";
    repo = "MCActivity";
    rev = version;
    hash = "sha256-UZtqTxYoYxlgqZuDSfKQvc+i3eY2ScI/WQPMSI8h7R8=";
  };

  patches = [ ./settings.patch ];

  npmDepsHash = "sha256-WWszhsBdOtLtxFz7QsA0vL0I+JTg9CJAtDpKifVJmtE=";
  dontNpmBuild = true;

  meta = {
    description = "MCActivity is a Discord bot that updates its activity based on your player count";
    homepage = "https://github.com/AshtonMemer/MCActivity";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.tie ];
    mainProgram = "mcactivity";
  };
}
