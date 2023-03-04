# Copied from pkgs/servers/pufferpanel/default.nix
# TODO: submit changes to Nixpkgs upstream.

{ lib
, buildGoModule
, fetchFromGitHub
, makeWrapper
, stdenv
, fetchzip
, pathDeps ? [ ]
}:

buildGoModule rec {
  pname = "pufferpanel";
  version = "2.6.6";

  patches = [
    # Seems to be an anti-feature.
    ./disable-group-checks.patch
    # See https://github.com/mattn/go-sqlite3/issues/803
    ./bump-sqlite.patch
  ];

  src = fetchFromGitHub {
    owner = "pufferpanel";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-0Vyi47Rkpe3oODHfsl/7tCerENpiEa3EWBHhfTO/uu4=";
  };

  # PufferPanel is split into two parts: the backend daemon and the
  # frontend.
  # Getting the frontend to build in the Nix environment fails even
  # with all the proper node_modules populated. To work around this,
  # we just download the built frontend and package that.
  frontend = fetchzip {
    url = "https://github.com/PufferPanel/PufferPanel/releases/download/v${version}/pufferpanel_${version}_linux_arm64.zip";
    hash = "sha256-z7HWhiEBma37OMGEkTGaEbnF++Nat8wAZE2UeOoaO/U=";
    stripRoot = false;
    postFetch = ''
      mv $out $TMPDIR/subdir
      mv $TMPDIR/subdir/www $out
    '';
  };

  nativeBuildInputs = [ makeWrapper ];

  subPackages = [ "cmd" ];
  vendorHash = "sha256-jJZ9Vyg+fyNZyAsQNrJTzCaGcxkCn33PWTpUj2syVjg=";
  proxyVendor = true;

  postFixup = ''
    mkdir -p $out/share/pufferpanel
    cp -r ${src}/assets/email $out/share/pufferpanel/templates
    cp -r ${frontend} $out/share/pufferpanel/www

    # Wrap the binary with the path to the external files.
    mv $out/bin/cmd $out/bin/pufferpanel
    wrapProgram "$out/bin/pufferpanel" \
      --set PUFFER_PANEL_EMAIL_TEMPLATES $out/share/pufferpanel/templates/emails.json \
      --set GIN_MODE release \
      --set PUFFER_PANEL_WEB_FILES $out/share/pufferpanel/www \
      --prefix PATH : ${lib.escapeShellArg (lib.makeBinPath pathDeps)}
  '';

  meta = with lib; {
    description = "A free, open source game management panel";
    homepage = "https://www.pufferpanel.com/";
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ ckie ];
    broken = stdenv.isDarwin; # never built on Hydra https://hydra.nixos.org/job/nixpkgs/trunk/pufferpanel.x86_64-darwin
  };
}
