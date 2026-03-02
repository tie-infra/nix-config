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
            match = [ { host = [ "brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "subroute";
                routes = [
                  {
                    match = [
                      {
                        expression = {
                          expr = "{http.request.uri}.endsWith(\"/\")";
                          name = "document"; # FIXME: caddy panics if name is nil
                        };
                      }
                    ];
                    handle = [
                      {
                        handler = "rewrite";
                        uri = "{http.request.uri}index.html";
                      }
                    ];
                  }
                  {
                    handle = [
                      {
                        handler = "rewrite";
                        uri = "/brim-website{http.request.uri}";
                      }
                    ];
                  }
                  {
                    handle = [
                      {
                        handler = "reverse_proxy";
                        upstreams = [ { dial = "localhost:9000"; } ];
                      }
                    ];
                  }
                ];
              }
            ];
          }
          {
            match = [ { host = [ "hunt-api.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "62.217.184.232:1896"; } ];
              }
            ];
          }
          {
            match = [ { host = [ "pubg-api.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "62.217.184.232:2017"; } ];
              }
            ];
          }
          {
            match = [ { host = [ "assets.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "static_response";
                status_code = 301; # Moved Permanently
                headers.Location = [ "https://brim.su/assets/" ];
              }
            ];
          }
          {
            match = [ { host = [ "ip.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "static_response";
                headers.Content-Type = [ "text/plain" ];
                body = "{http.request.remote.host}";
              }
            ];
          }
          {
            match = [ { host = [ "storage.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:9001"; } ];
              }
            ];
          }
          {
            match = [ { host = [ "s3.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:9000"; } ];
              }
            ];
          }
          {
            match = [ { host = [ "outline.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:3000"; } ];
              }
            ];
          }
          {
            match = [
              {
                host = [
                  "brimworld.online"
                  "wiki.brimworld.online"
                ];
              }
            ];
            terminal = true;
            handle = [
              {
                handler = "subroute";
                routes = [
                  {
                    match = [ { path = [ "/" ]; } ];
                    handle = [
                      {
                        handler = "static_response";
                        status_code = 302; # Found
                        headers.Location = [ "/s/3447b683-0b35-4ccd-b0cd-2f677ac812f4" ];
                      }
                    ];
                  }
                  {
                    handle = [
                      {
                        handler = "reverse_proxy";
                        upstreams = [ { dial = "localhost:3000"; } ];
                      }
                    ];
                  }
                ];
              }
            ];
          }
          {
            match = [
              {
                host = [
                  "panel.brim.su"
                  "panel.brimworld.online"
                ];
              }
            ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:8080"; } ];
              }
            ];
          }
          {
            match = [ { host = [ "sync.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:8384"; } ];
                headers.request.set.Host = [ "{http.reverse_proxy.upstream.hostport}" ];
              }
            ];
          }
          {
            match = [ { host = [ "git.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "static_response";
                status_code = 301; # Moved Permanently
                headers.Location = [ "https://github.com/Whitebrim" ];
              }
            ];
          }
          {
            match = [ { host = [ "tg.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "static_response";
                status_code = 301; # Moved Permanently
                headers.Location = [ "https://t.me/Whitebrim" ];
              }
            ];
          }
          {
            match = [ { host = [ "vk.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "static_response";
                status_code = 301; # Moved Permanently
                headers.Location = [ "https://vk.com/Whitebrim" ];
              }
            ];
          }
          {
            match = [ { host = [ "letmein.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "static_response";
                status_code = 302; # Found
                headers.Location = [ "https://brimworld.online/s/3447b683-0b35-4ccd-b0cd-2f677ac812f4/doc/anketa-E2ivmU3h16" ];
              }
            ];
          }
          {
            match = [ { host = [ "api.brim.su" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "rewrite";
                uri = "/brimworld-api{http.request.uri}";
              }
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:9000"; } ];
              }
            ];
          }
          {
            match = [ { host = [ "automodpack.brimworld.online" ]; } ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:30037"; } ];
              }
            ];
          }
          {
            match = [
              {
                host = [
                  "plan.brim.su"
                  "plan.brimworld.online"
                ];
              }
            ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:8804"; } ];
              }
            ];
          }
          {
            match = [
              {
                host = [
                  "map.brim.su"
                  "map-vanilla.brim.su"
                  "map.brimworld.online"
                  "map-vanilla.brimworld.online"
                ];
              }
            ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:18080"; } ];
              }
            ];
          }
          {
            match = [
              {
                host = [
                  "map-mods.brim.su"
                  "map-mods.brimworld.online"
                ];
              }
            ];
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "localhost:18081"; } ];
              }
            ];
          }
        ];
      };
      apps.tls.automation.policies = [
        {
          #subjects = [
          #  # TODO
          #];
          issuers = [
            {
              email = "dev@brim.su";
              module = "acme";
            }
          ];
        }
      ];
    };
  };
}
