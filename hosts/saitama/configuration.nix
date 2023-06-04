{ self, inputs, ... }:
{ lib, config, pkgs, ... }: {
  imports = [
    self.nixosModules.base-system
    self.nixosModules.erase-your-darlings
    self.nixosModules.trust-admins
    self.nixosModules.services
    inputs.sops-nix.nixosModules.default
    inputs.nixos-hardware.nixosModules.common-gpu-amd
  ];

  system.stateVersion = "23.05";

  time.timeZone = "Europe/Moscow";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    initrd.availableKernelModules = [ "ahci" "amd64_edac" ];

    kernel.sysctl = {
      # Transmission uses a single UDP socket in order to implement multiple uTP sockets,
      # and thus expects large kernel buffers for the UDP socket,
      # https://trac.transmissionbt.com/browser/trunk/libtransmission/tr-udp.c?rev=11956,
      # at least up to the values hardcoded here.
      #
      # Also needed for H3/QUIC in Caddy (though a smaller buffer size is sufficient),
      # https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size
      "net.core.rmem_max" = 4194304; # 4MB
      "net.core.wmem_max" = "1048576"; # 1MB
    };
  };

  hardware = {
    opengl.enable = true;
    amdgpu = {
      amdvlk = true;
      opencl = true;
    };
  };

  environment.systemPackages = [ pkgs.radeontop ];

  eraseYourDarlings =
    let disk = "WDC_WD10EALX-009BA0_WD-WCATR5170643";
    in {
      bootDisk = "/dev/disk/by-id/ata-${disk}-part1";
      rootDisk = "/dev/disk/by-id/ata-${disk}-part2";
    };

  networking = {
    hostName = "saitama";
    firewall = {
      allowedTCPPorts = [
        # Caddy
        443
        # Netdata
        19999
        # Transmission (BitTorrent traffic)
        51413
      ];
      allowedUDPPorts = [
        # Caddy
        443
        # Transmission (BitTorrent traffic)
        51413
      ];
    };
  };

  services = {
    netdata.enable = true;

    caddy = {
      enable = true;
      email = "mr.trubach@icloud.com";
      extraConfig = builtins.readFile ./Caddyfile;
    };

    jellyfin = {
      enable = true;
      # Allow access to the Sonarr media library.
      extraGroups = [ config.users.groups.sonarr.name ];
    };

    sonarr = {
      enable = true;
      # Allow access to the Transmission downloads.
      extraGroups = [ config.users.groups.transmission.name ];
    };

    jackett = {
      enable = true;
      settings = {
        BasePathOverride = "/jackett";
        CacheEnabled = true;
        CacheTtl = 86400;
        CacheMaxResultsPerIndexer = 100000;
      };
    };

    transmission = {
      enable = true;
      settings = {
        port-forwarding-enabled = false;

        rpc-authentication-required = true;

        download-queue-enabled = true;
        download-queue-size = 10;

        ratio-limit-enabled = true;
        ratio-limit = 4.0;

        speed-limit-down-enabled = true;
        speed-limit-down = 65536; # KB/s | ~50MB

        speed-limit-up-enabled = true;
        speed-limit-up = 65536; # KB/s | ~50MB

        alt-speed-enabled = false;
        alt-speed-up = 1024; # KB/s | ~1MB
        alt-speed-down = 1024; # KB/s | ~1MB
      };
      settingsFile = config.sops.secrets."transmission/settings.json".path;
    };
  };

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
  systemd.services.jellyfin.environment = {
    HTTP_PROXY = "http://[::1]:3128";
    HTTPS_PROXY = "http://[::1]:3128";
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      "transmission/settings.json" = {
        restartUnits = [ "transmission.service" ];
      };
    };
  };
}
