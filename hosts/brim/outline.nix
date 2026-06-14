{
  config,
  ...
}:
{
  services.outline.enable = true;

  services.redis.servers.outline = {
    enable = true;
    bind = "::1 127.0.0.1";
  };

  systemd.services.outline = {
    environment = {
      NODE_ENV = "production";

      URL = "https://brimworld.online";
      CDN_URL = "https://brimworld.online";
      PORT = "3000";

      DATABASE_URL = "postgresql://localhost/outline?user=outline&host=/run/postgresql&sslmode=disable";
      REDIS_URL = "unix://${config.services.redis.servers.outline.unixSocket}";

      DISCORD_SERVER_ID = "925681822766092319"; # BrimWorld
      DISCORD_SERVER_ROLES = "925695895880761345,1281827267634401341"; # Admin, Wiki editor
      DISCORD_CLIENT_ID = "1279604766476861451";
      # DISCORD_CLIENT_SECRET is set from EnvironmentFile.

      FILE_STORAGE = "s3";
      AWS_ACCESS_KEY_ID = "GK862735dd1f68931f2baa1948";
      AWS_REGION = "garage";
      # AWS_SECRET_ACCESS_KEY is set from EnvironmentFile.
      AWS_S3_UPLOAD_BUCKET_URL = "https://s3.brim.su";
      AWS_S3_UPLOAD_BUCKET_NAME = "outline";
      AWS_S3_FORCE_PATH_STYLE = "1";

      FILE_STORAGE_UPLOAD_MAX_SIZE = "100000000"; # 100 MB
    };

    restartTriggers = [ config.sops.templates."outline.env".file ];

    serviceConfig = {
      EnvironmentFile = config.sops.templates."outline.env".path;
      SupplementaryGroups = [
        config.users.groups.postgres.name
        config.services.redis.servers.outline.user
      ];
    };
  };

  sops.templates."outline.env".content = ''
    SECRET_KEY=${config.sops.placeholder."outline/secret-key"}
    UTILS_SECRET=${config.sops.placeholder."outline/utils-secret"}
    DISCORD_CLIENT_SECRET=${config.sops.placeholder."outline/discord-client-secret"}
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."outline/s3-secret-access-key"}
  '';

  sops.secrets = {
    "outline/secret-key" = {
      restartUnits = [ "outline.service" ];
      sopsFile = ../../secrets/brim.sops.yaml;
    };
    "outline/utils-secret" = {
      restartUnits = [ "outline.service" ];
      sopsFile = ../../secrets/brim.sops.yaml;
    };
    "outline/discord-client-secret" = {
      restartUnits = [ "outline.service" ];
      sopsFile = ../../secrets/brim.sops.yaml;
    };
    "outline/s3-secret-access-key" = {
      restartUnits = [ "outline.service" ];
      sopsFile = ../../secrets/brim.sops.yaml;
    };
  };
}
