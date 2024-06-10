{ lib, pkgs, config, ... }: {
  environment = {
    systemPackages = with pkgs; [
      ripgrep
      fd
      file
      tree
      htop
      btop
      duf
      dstat
      vim
      rcon
      mc
    ];
    shellAliases = {
      lsd = "lsblk --nodeps --output=MODEL,SERIAL,SIZE,NAME,TYPE,TRAN,FSTYPE --sort=NAME";
    };
    variables = {
      # Most terminals are dark, but ip from iproute2 assumes otherwise.
      # See also https://unix.stackexchange.com/a/245568
      COLORFGBG = ";0";
    };
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  zramSwap.enable = true;

  networking = {
    useNetworkd = true;

    # Disables DHCP on `en*` and `eth*` interfaces.
    # See https://github.com/NixOS/nixpkgs/blob/2920b6fc16a9ed5d51429e94238b28306ceda79e/nixos/modules/tasks/network-interfaces-systemd.nix#L49-L56
    #
    # We enable DHCP in installer and bootstrap systems, but otherwise network
    # configuration is host-specific.
    useDHCP = lib.mkDefault false;

    firewall.logRefusedConnections = lib.mkDefault false;
  };

  systemd.network.config = {
    # Enable traffic meters on all interfaces.
    # https://www.freedesktop.org/software/systemd/man/networkd.conf.html#SpeedMeter=
    networkConfig = {
      SpeedMeter = true;
    };
  };

  security.polkit.enable = true;

  users = {
    mutableUsers = false;
    users.nixos = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = with config.users.groups;
        [ wheel.name disk.name ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIPgvPYPtXXqGGerR7k+tbrIG2fCzp3R8ox7mkKRIdEu actions@github.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAKU7x1o6NPI/7AqwCaC8edvl80//2LgyVSV/3tIfb mr.trubach@icloud.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3MFVFbEvoiXBpqPavtwDIQtgY1hLXNvJgTY7/nasG/ dev@brim.su"
      ];
    };
  };

  services = {
    getty.autologinUser = config.users.users.nixos.name;

    resolved.enable = true;

    openssh = {
      enable = true;
      startWhenNeeded = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      extraConfig = ''
        LoginGraceTime 15s
        RekeyLimit default 30m
      '';
    };
  };
}
