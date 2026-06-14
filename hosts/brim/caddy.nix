{
  config,
  ...
}:
let
  httpsPort = 443;
in
{
  networking.firewall = {
    allowedUDPPorts = [ httpsPort ];
    allowedTCPPorts = [ httpsPort ];
  };

  services.caddy = {
    enable = true;
    settings = {
      apps.http.servers.default = {
        listen = [ ":${toString httpsPort}" ];
      };
      apps.tls = {
        certificates.automate = [
          "brim.su"
          "*.brim.su"
          "brimworld.online"
          "*.brimworld.online"
        ];
        automation.policies = [
          {
            issuers = [
              {
                module = "acme";
                email = "dev@brim.su";
                challenges.dns = {
                  provider = {
                    name = "cloudflare";
                    api_token = "{env.CLOUDFLARE_DNS_API_TOKEN}";
                  };
                };
              }
            ];
          }
        ];
      };
    };
  };

  systemd.services.caddy = {
    serviceConfig = {
      EnvironmentFile = [
        config.sops.templates."caddy.env".path
      ];
    };
  };

  sops.templates."caddy.env" = {
    content = ''
      CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/dns-api-token"}
    '';
  };

  sops.secrets."cloudflare/dns-api-token" = {
    sopsFile = ../../secrets/brim.sops.yaml;
    restartUnits = [ config.systemd.services.caddy.name ];
  };
}
