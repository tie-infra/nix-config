{
  services.caddy = {
    enable = true;
    settings = {
      apps.http.servers.default = {
        listen = [ ":443" ];
        routes = [
          {
            match = [ { host = [ "jellyfin.tie.rip" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:8096"; } ];
              }
            ];
          }
          {
            match = [ { host = [ "prowlarr.tie.rip" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:9696"; } ];
              }
            ];
          }
          {
            match = [ { host = [ "radarr.tie.rip" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:7878"; } ];
              }
            ];
          }
          {
            match = [ { host = [ "sonarr.tie.rip" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:8989"; } ];
              }
            ];
          }
          {
            match = [ { host = [ "flood.tie.rip" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:9092"; } ];
              }
            ];
          }
        ];
      };
      apps.tls.automation.policies = [
        {
          subjects = [
            "jellyfin.tie.rip"
            "prowlarr.tie.rip"
            "radarr.tie.rip"
            "sonarr.tie.rip"
            "flood.tie.rip"
          ];
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
