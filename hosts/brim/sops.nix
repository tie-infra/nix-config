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

  sops.templates."outline.env".content = ''
    SECRET_KEY=${config.sops.placeholder."outline/secret-key"}
    UTILS_SECRET=${config.sops.placeholder."outline/utils-secret"}
    DISCORD_CLIENT_SECRET=${config.sops.placeholder."outline/discord-client-secret"}
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."outline/s3-secret-access-key"}
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
      "outline/secret-key" = {
        restartUnits = [ "outline.service" ];
        sopsFile = ./secrets.yaml;
      };
      "outline/utils-secret" = {
        restartUnits = [ "outline.service" ];
        sopsFile = ./secrets.yaml;
      };
      "outline/discord-client-secret" = {
        restartUnits = [ "outline.service" ];
        sopsFile = ./secrets.yaml;
      };
      "outline/s3-secret-access-key" = {
        restartUnits = [ "outline.service" ];
        sopsFile = ./secrets.yaml;
      };
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
