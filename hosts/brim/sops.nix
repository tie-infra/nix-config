{ config, lib, ... }: {
  passthru.caddySecrets = [
    "brim-su-key.pem"
    "brimworld-online-key.pem"
  ];

  sops.templates."minio.env".content = ''
    MINIO_ROOT_PASSWORD=${config.sops.placeholder."minio/root-password"}
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
      "minio/root-password" = {
        restartUnits = [ "minio.service" ];
        sopsFile = ./secrets.yaml;
      };
    };
}
