let
  guiPort = 8384;
in
{
  services.caddy.settings.apps.http.servers.default = {
    routes = [
      {
        match = [ { host = [ "sync.brim.su" ]; } ];
        handle = [
          {
            handler = "reverse_proxy";
            upstreams = [ { dial = "localhost:${toString guiPort}"; } ];
            headers.request.set.Host = [ "{http.reverse_proxy.upstream.hostport}" ];
          }
        ];
      }
    ];
  };

  services.syncthing = {
    enable = true;
    guiAddress = ":${toString guiPort}";
    overrideFolders = false;
    overrideDevices = false;
    openDefaultPorts = true;
  };
}
