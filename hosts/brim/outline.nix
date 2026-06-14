{
  config,
  ...
}:
let
  outlinePort = 3000;
in
{
  services.caddy.settings.apps.http.servers.default = {
    routes = [
      {
        match = [
          {
            host = [
              "brimworld.online"
              "wiki.brimworld.online"
            ];
            path = [ "/" ];
          }
        ];
        handle = [
          {
            handler = "static_response";
            status_code = 302; # Found
            headers.Location = [ "/s/3447b683-0b35-4ccd-b0cd-2f677ac812f4" ];
          }
        ];
      }
      {
        match = [
          {
            host = [
              "outline.brim.su"
              "brimworld.online"
              "wiki.brimworld.online"
            ];
          }
        ];
        handle = [
          {
            handler = "reverse_proxy";
            upstreams = [ { dial = "localhost:${toString outlinePort}"; } ];
          }
        ];
      }
    ];
  };

  services.outline = {
    enable = true;
  };

  services.redis.servers.outline = {
    enable = true;
    bind = "::1 127.0.0.1";
  };

  systemd.services.outline = {
    environment = {
      NODE_ENV = "production";

      URL = "https://outline.brim.su";
      CDN_URL = "https://outline.brim.su";
      PORT = toString outlinePort;

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

    serviceConfig = {
      EnvironmentFile = [
        config.sops.templates."outline.env".path
      ];
      SupplementaryGroups = [
        config.users.groups.postgres.name
        config.services.redis.servers.outline.user
      ];
    };
  };

  sops.templates."outline.env" = {
    content = ''
      SECRET_KEY=${config.sops.placeholder."outline/secret-key"}
      UTILS_SECRET=${config.sops.placeholder."outline/utils-secret"}
      DISCORD_CLIENT_SECRET=${config.sops.placeholder."outline/discord-client-secret"}
      AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."outline/s3-secret-access-key"}
    '';
    restartUnits = [
      config.systemd.services.outline.name
    ];
  };

  sops.secrets."outline/secret-key" = {
    sopsFile = ../../secrets/brim.sops.yaml;
    restartUnits = [
      config.systemd.services.outline.name
    ];
  };

  sops.secrets."outline/utils-secret" = {
    sopsFile = ../../secrets/brim.sops.yaml;
    restartUnits = [
      config.systemd.services.outline.name
    ];
  };

  sops.secrets."outline/discord-client-secret" = {
    sopsFile = ../../secrets/brim.sops.yaml;
    restartUnits = [
      config.systemd.services.outline.name
    ];
  };

  sops.secrets."outline/s3-secret-access-key" = {
    sopsFile = ../../secrets/brim.sops.yaml;
    restartUnits = [
      config.systemd.services.outline.name
    ];
  };
}
