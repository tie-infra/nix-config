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

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      "transmission/settings.json" = {
        restartUnits = [ "transmission.service" ];
      };
    };
  };
}
