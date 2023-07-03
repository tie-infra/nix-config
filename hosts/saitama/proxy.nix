{ lib, ... }: {
  # .NET lacks Happy Eyeballs support and some requests are routed over bogus
  # ISPs with broken or slow IPv6 connectivity.
  # See https://github.com/dotnet/runtime/issues/26177
  # See https://learn.microsoft.com/en-us/dotnet/core/runtime-config/networking
  #
  # Unfortunately, DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER doesn’t fix the
  # issue for some reason. As a workaround, we set up a local HTTP proxy.
  #
  services._3proxy = {
    enable = true;
    services = [{
      type = "proxy";
      auth = [ "none" ];
      bindAddress = "::1";
      bindPort = 3128;
    }];
  };
  services.jackett.settings = {
    # Jackett doesn’t respect HTTP_PROXY and HTTPS_PROXY environment variables
    # for some reason.
    ProxyType = 0; # HTTP
    ProxyUrl = "http://[::1]:3128";
  };
  systemd.services = lib.genAttrs [ "sonarr" "jellyfin" ] (_: {
    environment = {
      HTTP_PROXY = "http://[::1]:3128";
      HTTPS_PROXY = "http://[::1]:3128";
    };
  });
}
