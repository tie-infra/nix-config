let
  mcpHost = "mcp.tie.rip";

  mcpAtlassianPort = 9000;
  mcpAtlassianPath = "/atlassian";
in
{
  config,
  ...
}:
{
  services.mcp-atlassian = {
    enable = true;
    environment = {
      TRANSPORT = "streamable-http";
      STATELESS = "true";
      HOST = "::1";
      PORT = toString mcpAtlassianPort;
      STREAMABLE_HTTP_PATH = mcpAtlassianPath;

      # https://mcp-atlassian.soomiles.com/docs/tools-reference
      TOOLSETS = "default";
    };
  };

  services.caddy.settings.apps.http.servers.default = {
    routes = [
      {
        match = [ { host = [ mcpHost ]; } ];
        handle = [
          {
            handler = "authentication";
            providers.http_basic = {
              hash_cache = { };
              accounts = [
                {
                  username = "mcp";
                  password = "{env.MCP_BASIC_AUTH_PASSWORD_HASH}";
                }
              ];
            };
          }
          {
            handler = "subroute";
            routes = [
              {
                match = [ { path = [ mcpAtlassianPath ]; } ];
                handle = [
                  {
                    handler = "reverse_proxy";
                    upstreams = [ { dial = "localhost:${toString mcpAtlassianPort}"; } ];
                    headers.request.delete = [ "Authorization" ];
                  }
                ];
              }
            ];
          }
        ];
      }
    ];
  };

  systemd.services.caddy = {
    serviceConfig = {
      EnvironmentFile = [
        config.sops.templates."mcp-basic-auth.env".path
      ];
    };
  };

  sops.templates."mcp-basic-auth.env" = {
    restartUnits = [ config.systemd.services.caddy.name ];
    content = ''
      MCP_BASIC_AUTH_PASSWORD_HASH=${config.sops.placeholder.mcp-basic-auth-password-hash}
    '';
  };

  sops.secrets.mcp-basic-auth-password-hash = {
    restartUnits = [ config.systemd.services.caddy.name ];
    sopsFile = ../../secrets/mcp.sops.yaml;
  };
}
