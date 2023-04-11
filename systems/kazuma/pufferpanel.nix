_: _:
{ pkgs, config, ... }: {
  #virtualisation.podman.enable = true;
  #virtualisation.podman.dockerSocket.enable = true;
  #virtualisation.podman.dockerCompat = true;

  services.pufferpanel = {
    enable = true;
    openFirewall = true;
    extraPackages = [ pkgs.jre8 ];
    #extraGroups = [ "podman" ];
    panel.enable = false;
    daemon.auth = {
      url = "https://panel.brim.ml/oauth2/token";
      clientId = ".node_2";
      clientSecretFile = config.age.secrets.pufferpanel-client-secret.path;
    };
    environment = {
      PUFFER_TOKEN_PUBLIC = "https://panel.brim.ml/auth/publickey";
      PUFFER_DAEMON_CONSOLE_BUFFER = "1000";
    };
  };

  age.secrets.pufferpanel-client-secret = {
    file = ./pufferpanel-client-secret.age;
  };
}
