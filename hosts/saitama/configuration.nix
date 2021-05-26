{ config, lib, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../profiles/nix-flakes.nix
    ../../profiles/avahi-mdns.nix
    ../../profiles/openssh.nix
    ../../profiles/networkd-debug.nix
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

    # We are in native IPv6 dual-stack network.
    enableIPv6 = true;

    # Disable default DHCP, otherwise NixOS tries to lease DHCP
    # addresses on all available interfaces. The docs also state
    # that this behavior will eventually be deprecated and removed.
    useDHCP = false;

    # Enable systemd-networkd instead of default networking scripts.
    useNetworkd = true;
  };

  # FIXME: systemd discards leases on reboot https://github.com/systemd/systemd/issues/16924
  # That’s a real issue since network’s DHCP server DOES NOT assign new addresses for the
  # same MAC address (and DUID?) until the last lease expires. We’d need something like a
  # patch from https://github.com/systemd/systemd/pull/16920
  #
  # And the root cause is that DHCPv6 client apparently does not release addresses on shutdown.
  # See also https://github.com/systemd/systemd/issues/19728
  #
  systemd.network.enable = true;
  systemd.network.networks.IPv4 = {
    matchConfig = { Name = "enp2s0"; };
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = false;
      LinkLocalAddressing = "ipv4";
    };
    dhcpV4Config = { ClientIdentifier = "mac"; };
  };
  systemd.network.networks.IPv6 = {
    matchConfig = { Name = "enp3s0"; };
    networkConfig = {
      DHCP = "ipv6";
      IPv6AcceptRA = true;
      LinkLocalAddressing = "ipv6";
    };
    ipv6AcceptRAConfig = { DHCPv6Client = "always"; };
    # Actually dhcpV6Config. See https://github.com/systemd/systemd/issues/18996
    # TODO: change on systemd 248 release.
    dhcpV4Config = { ClientIdentifier = "mac"; };
  };

  systemd.tmpfiles.rules = [
    # ssh
    "d /persist/ssh - - - - -"
    "z /persist/ssh 0750 - - - -"
  ];
  # FIXME: that would fail on reinstall.
  environment.etc."machine-id".source = "/persist/machine-id";

  nix = {
    # Trust all admins.
    trustedUsers = [ "@wheel" ];
    # Remove generations older than one weeks.
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
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
