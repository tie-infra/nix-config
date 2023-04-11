_: _:
let clientSecretFile = "/run/secrets/pufferpanel-client-secret";
in { pkgs, ... }: {
  #services.pufferpanel-deprecated = {
  #  enable = true;
  #  packages = with pkgs; [ jre8 bash git coreutils-full wget curl gnutar xz unzip mono ];
  #  panel.enable = false;
  #  daemon.enable = true;
  #  daemon.auth = {
  #    inherit clientSecretFile;
  #    clientId = ".node_2";
  #    url = "https://panel.brim.ml/oauth2/token";
  #  };
  #  token.public = "https://panel.brim.ml/auth/publickey";
  #  workDir = "/persist/pufferpanel";
  #};
  #
  #networking.firewall.allowedTCPPorts = [ 18080 ];
  #containers.pufferpanel = {
  #  autoStart = true;
  #  forwardPorts = [
  #    {
  #      containerPort = 18080;
  #      hostPort = 18080;
  #      protocol = "tcp";
  #    }
  #  ];
  #  config = { lib, pkgs, ... }: {
  #    system.stateVersion = "22.11";
  #
  #    environment.systemPackages = [
  #      pkgs.pufferpanel
  #      pkgs.file
  #    ];
  #
  #    virtualisation.podman.enable = true;
  #    virtualisation.podman.dockerSocket.enable = true;
  #    virtualisation.podman.dockerCompat = true;
  #
  #    systemd.services.pufferpanel.serviceConfig.RestrictNamespaces = lib.mkForce [ "mnt" "user" ];
  #    services.pufferpanel = {
  #      enable = true;
  #      extraPackages = with pkgs; [ bash curl gawk gnutar gzip steam-run ];
  #      package = pkgs.buildFHSUserEnv {
  #        name = "pufferpanel-fhs";
  #        runScript = lib.getExe pkgs.pufferpanel;
  #        targetPkgs = pkgs: with pkgs; [ icu openssl zlib ];
  #      };
  #
  #      port = 18080;
  #      daemon.sftp.port = 15657;
  #      panel.registrationEnabled = false;
  #
  #      extraGroups = [ "podman" ];
  #      environment = {
  #        PUFFER_DAEMON_CONSOLE_BUFFER = "1000";
  #      };
  #    };
  #  };
  #};
  age.secrets.pufferpanel-client-secret = {
    file = ./pufferpanel-client-secret.age;
    mode = "0444";
    path = clientSecretFile;
  };
}
