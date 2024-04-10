{ config, lib, ... }: {
  passthru.caddySecrets = [
    "brim-su-key.pem"
    "brimworld-online-key.pem"
  ];

  sops.templates."minio.env".content = ''
    MINIO_ROOT_PASSWORD=${config.sops.placeholder."minio/root-password"}
  '';

  sops.templates."mcactivity.env".content = ''
    MCACTIVITY_BOT_TOKEN=${config.sops.placeholder."discord/brimworld-bot-token"}
  '';

  sops.secrets =
    lib.listToAttrs
      (map
        (secret: {
          name = "caddy/" + secret;
          value = {
            restartUnits = [ "caddy.service" ];
            sopsFile = ./secrets.yaml;
          };
        })
        config.passthru.caddySecrets)
    // {
      "discord/brimworld-bot-token" = {
        restartUnits = [ "mcactivity.service" ];
        sopsFile = ./secrets.yaml;
      };
      "minio/root-password" = {
        restartUnits = [ "minio.service" ];
        sopsFile = ./secrets.yaml;
      };
    };
}
