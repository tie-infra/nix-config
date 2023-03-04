_: _:
let clientSecretFile = "/run/secrets/pufferpanel-client-secret";
in { pkgs, ... }: {
  services.pufferpanel = {
    enable = true;
    packages = [ pkgs.jre8 ];
    panel.enable = false;
    daemon.enable = true;
    daemon.auth = {
      inherit clientSecretFile;
      clientId = ".node_2";
      url = "https://panel.brim.ml/oauth2/token";
    };
    token.public = "https://panel.brim.ml/auth/publickey";
    workDir = "/persist/pufferpanel";
  };

  age.secrets.pufferpanel-client-secret = {
    file = ./pufferpanel-client-secret.age;
    mode = "0444";
    path = clientSecretFile;
  };
}
