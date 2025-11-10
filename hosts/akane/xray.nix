{
  config,
  ...
}:
let
  socketPath = "/run/xray/xray.socket";
in
{
  services.xray = {
    enable = true;
    settings = {
      inbounds = [
        {
          listen = socketPath;
          protocol = "vless";
          settings = {
            decryption = "none";
            clients = [
              {
                id = "673ca02a-b688-5b1f-9311-16d4125f017d";
              }
            ];
          };
          streamSettings = {
            network = "xhttp";
          };
        }
      ];
      outbounds = [
        {
          protocol = "freedom";
        }
      ];
    };
  };

  users = {
    users.xray = {
      isSystemUser = true;
      group = config.users.groups.xray.name;
    };
    groups.xray = { };
  };

  systemd.services.xray = {
    serviceConfig = {
      User = config.users.users.xray.name;
      Group = config.users.groups.xray.name;
      RuntimeDirectory = "xray";
      RuntimeDirectoryMode = "0750";
    };
  };

  services.caddy.settings.apps.http.servers.default = {
    routes = [
      {
        match = [ { host = [ "vless.tie.rip" ]; } ];
        handle = [
          {
            handler = "authentication";
            providers.http_basic = {
              hash_cache = { };
              accounts = [
                {
                  username = "xray";
                  password = "{env.XRAY_BASIC_AUTH_PASSWORD_HASH}";
                }
              ];
            };
          }
          {
            handler = "reverse_proxy";
            upstreams = [
              {
                dial = "unix/${socketPath}";
              }
            ];
            transport = {
              protocol = "http";
              versions = [ "h2c" ];
            };
          }
        ];
      }
    ];
  };

  systemd.services.caddy = {
    serviceConfig = {
      SupplementaryGroups = [ config.users.groups.xray.name ];
      EnvironmentFile = [
        config.sops.templates."caddy-xray.env".path
      ];
    };
  };

  sops.templates."caddy-xray.env" = {
    restartUnits = [ config.systemd.services.caddy.name ];
    content = ''
      XRAY_BASIC_AUTH_PASSWORD_HASH=${config.sops.placeholder.xray-basic-auth-password-hash}
    '';
  };

  sops.secrets.xray-basic-auth-password-hash = {
    restartUnits = [ config.systemd.services.caddy.name ];
    sopsFile = ../../secrets/xray.sops.yaml;
  };
}
