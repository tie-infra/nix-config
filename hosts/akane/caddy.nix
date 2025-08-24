{
  networking.firewall = {
    allowedUDPPorts = [ 443 ];
    allowedTCPPorts = [ 443 ];
  };

  services.caddy = {
    enable = true;
    settings = {
      apps.http.servers.default = {
        listen = [ ":443" ];
        routes = [
          {
            match = [ { host = [ "tie.rip" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "static_response";
                body = "Hello, world!";
              }
            ];
          }
        ];
      };
      apps.tls.automation.policies = [
        {
          subjects = [ "tie.rip" ];
          issuers = [
            {
              email = "mr.trubach@icloud.com";
              module = "acme";
            }
          ];
        }
      ];
    };
  };
}
