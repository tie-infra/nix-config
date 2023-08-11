{ self, inputs, ... }:
{ lib, config, pkgs, ... }: {
  imports = [
    self.nixosModules.base-system
    self.nixosModules.erase-your-darlings
    self.nixosModules.trust-admins
    self.nixosModules.btrfs-on-bcache
    inputs.sops-nix.nixosModules.default
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    ./proxy.nix
  ];

  system.stateVersion = "23.05";

  time.timeZone = "Europe/Moscow";

  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    initrd.availableKernelModules = [
      "amd64_edac"
      "nvme"
      "ahci"
      "bcache"
    ];

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

  environment = {
    systemPackages = [ pkgs.radeontop ];

    machineInfo = {
      chassis = "server";
      location = "Ivan’s homelab";
    };
  };

  eraseYourDarlings = {
    bootDisk = "/dev/disk/by-uuid/6846-A71E";
    rootDisk = "/dev/disk/by-uuid/e461062c-c7cf-449e-b661-97d84d07f596";
  };

  btrfsOnBcache.enable = true;

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

  systemd.network.networks."10-wan" = {
    matchConfig = {
      Name = "enp6s0";
    };
    networkConfig = {
      DHCP = "yes";
      IPv6PrivacyExtensions = "kernel";
    };
    dhcpV6Config = {
      UseDelegatedPrefix = false;
    };
    linkConfig = {
      RequiredForOnline = "routable";
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
      mediaFolders = [ "anime" "tvshows" "onepiece" ];
      # Allow access to the Transmission downloads.
      extraGroups = [ config.users.groups.transmission.name ];
    };

    jackett = {
      enable = true;
      settings = {
        CacheEnabled = true;
        CacheTtl = 86400;
        CacheMaxResultsPerIndexer = 100000;
      };
      settingsFile = config.sops.secrets."jackett/settings.json".path;
    };

    flood = {
      enable = true;
      package = with pkgs; buildNpmPackage {
        pname = "flood";
        version = "unstable-2023-08-04";
        src = fetchFromGitHub {
          owner = "jesec";
          repo = "flood";
          rev = "2b652f8148dab7134eeeb201b9d81dd6b8bda074";
          hash = "sha256-wI6URPGUZUbydSgNaHN2C5IA2x/HHjBWIRT6H6iZU/0=";
        };
        npmDepsHash = "sha256-XmDnvq+ni5TOf3UQFc4JvGI3LiGpjbrLAocRvrW8qgk=";
      };
      extraFlags = [ "--host=::" "--port=9092" ];
      extraGroups = [ config.users.groups.transmission.name ];
    };

    transmission = {
      enable = true;
      settings = {
        port-forwarding-enabled = false;

        rpc-enabled = true;
        rpc-whitelist-enabled = false;
        rpc-authentication-required = true;
        rpc-bind-address = "::";
        rpc-port = 9091;

        peer-limit-global = 1000; # default is 240
        peer-limit-per-torrent = 100; # default is 60

        download-queue-enabled = true;
        download-queue-size = 10;

        ratio-limit-enabled = true;
        ratio-limit = 10.0;

        speed-limit-down-enabled = true;
        speed-limit-down = 65536; # KB/s

        speed-limit-up-enabled = true;
        speed-limit-up = 65536; # KB/s

        alt-speed-enabled = false;
        alt-speed-up = 1024; # KB/s
        alt-speed-down = 1024; # KB/s
      };
      settingsFile = config.sops.secrets."transmission/settings.json".path;
    };
  };

  # Getting an error when trying to download metadata.
  # 
  # System.IO.PathTooLongException: Path is too long. Path: /var/lib/sonarr/media/anime/KamiKatsu - Working for God in a Godless World (2023) [tvdb-419126]/Season 01/KamiKatsu - Working for God in a Godless World (2023) - S01E01 - 001 - We know we are not worthy O great Lord Mitama Please purify us Please cleanse us Lord Mitama We beg for you to hear our prayer [HDTV-1080p][8bit][x264][AAC 2.0][JA]-SubsPlease-thumb.jpg.part
  #
  # https://github.com/Sonarr/Sonarr/blob/dee8820b1f31e9180c55c6d29b950ff6cfe0205f/src/NzbDrone.Common/Disk/LongPathSupport.cs#L47
  # https://github.com/Sonarr/Sonarr/blob/dee8820b1f31e9180c55c6d29b950ff6cfe0205f/src/NzbDrone.Common/Http/HttpClient.cs#L251
  systemd.services.sonarr.environment.MAX_NAME = "225";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      "jackett/settings.json" = {
        restartUnits = [ "jackett.service" ];
      };
      "transmission/settings.json" = {
        restartUnits = [ "transmission.service" ];
      };
    };
  };
}
