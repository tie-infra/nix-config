{ config, lib, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../profiles/nix-flakes.nix
    ../../profiles/avahi-mdns.nix
    ../../profiles/openssh.nix
  ];

  system.stateVersion = "20.09";

  # Note that it’s a legacy BIOS system that uses CloverEFI.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = false;

  boot.initrd.availableKernelModules = [
    "ahci"
    "ohci_pci"
    "ehci_pci"
    "pata_atiixp"
    "firewire_ohci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.supportedFilesystems = [ "zfs" ];

  # See https://grahamc.com/blog/erase-your-darlings
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank
  '';

  fileSystems."/" = {
    device = "rpool/local/root";
    fsType = "zfs";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-id/ata-WDC_WD1001FALS-00J7B0_WD-WMATV0977093-part1";
    fsType = "vfat";
  };
  fileSystems."/nix" = {
    device = "rpool/local/nix";
    fsType = "zfs";
  };
  fileSystems."/persist" = {
    device = "rpool/safe/persist";
    fsType = "zfs";
    neededForBoot = true;
  };

  time.timeZone = "Europe/Moscow";

  networking = {
    hostName = "saitama";
    hostId = "c2e4086f";

    # Suppress dmesg log spam.
    firewall.logRefusedConnections = false;

    # We are in native IPv6 dual-stack network!
    enableIPv6 = true;

    # Disable default DHCP, otherwise NixOS tries to lease DHCP
    # addresses on all available interfaces. The docs also state
    # that this behavior will eventually be deprecated and removed.
    useDHCP = false;

    interfaces.enp3s0.useDHCP = true;
    dhcpcd.extraConfig = "ipv4only";

    # Both default dhcpcd and systemd-networkd don’t work on this network for some reason.
    # What’s even more weird is that dhcpcd (though an older version) on Alpine host is working.
    # To be fair, that was after some non-trivial efforts and at least Nix configuration is
    # reproducible.
    dibbler-client.enable = true;
    dibbler-client.extraConfig = ''
      iface enp3s0 {
         rapid-commit yes
         ia
         option dns-server
      }
    '';
  };

  systemd.mounts = [{
    type = "none";
    options = "bind";
    what = "/persist/dibbler";
    where = "/var/lib/dibbler";
    requiredBy = [ "dibbler-client.service" ];
    unitConfig = {
      RequiresMountsFor = "/persist";
      ConditionPathIsDirectory = "/persist/dibbler";
    };
  }];

  systemd.tmpfiles.rules = [
    # ssh
    "d /persist/ssh - - - - -"
    "z /persist/ssh 0750 - - - -"
    # dhcpcd
    "d /persist/dhcpcd - - - - -"
    "z /persist/dhcpcd 0750 - - - -"
    "L+ /var/db/dhcpcd - - - - /persist/dhcpcd"
    # dibbler
    "d /persist/dibbler - - - - -"
    "z /persist/dibbler 0750 - - - -"
  ];

  nix = {
    # Trust all admins.
    trustedUsers = [ "@wheel" ];
    # Remove generations older than 2 weeks.
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  users = {
    mutableUsers = false;
    users.nixos = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPSTOhvWnmozjnk82eW9yzb7Flty48PwsNTF+KItdv5w actions-user@github.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAKU7x1o6NPI/7AqwCaC8edvl80//2LgyVSV/3tIfb tie@xhyve"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFOq52CJ77uZJ7lDpRgODDMaO22PeHi1GB+rRyj7j+o1 tie@goro"
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  services.zfs.autoSnapshot.enable = true;
  services.zfs.autoScrub.enable = true;

  services.openssh.hostKeys = [{
    path = "/persist/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];
}
