{ config, pkgs, ... }: {
  system.stateVersion = "20.09";

  imports = [ ./hardware.nix ];

  networking.hostName = "nia";
  networking.hostId = "c2e4086f";

  time.timeZone = "Europe/Moscow";

  services.zfs.autoSnapshot.enable = true;
  services.zfs.autoScrub.enable = true;

  networking.firewall.logRefusedConnections = false;

  networking.enableIPv6 = true;
  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;
  networking.dhcpcd.extraConfig = "ipv4only";
  # Both default dhcpcd and systemd-networkd don’t work on this network for some reason.
  # What’s even more weird is that dhcpcd (though an older version) on Alpine host is working.
  # To be fair, that was after some non-trivial efforts and at least Nix configuration is
  # reproducible.
  systemd.services.dibbler-client = {
    description = "Portable DHCPv6 client";
    wantedBy = [ "multi-user.target" "network-online.target" ];
    wants = [ "network.target" ];
    before = [ "network-online.target" ];
    unitConfig.ConditionCapability = "CAP_NET_ADMIN";
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.dibbler}/bin/dibbler-client run";
      Restart = "always";
      PrivateTmp = true;
    };
  };
  # See http://klub.com.pl/dhcpv6/doc/dibbler-user.pdf
  environment.etc."dibbler/client.conf".text = ''
    inactive-mode
    iface enp3s0 {
       rapid-commit yes
       ia
       option dns-server
    }
  '';
  systemd.tmpfiles.rules = [
    "L /var/db/dhcpcd - - - - /persist/dhcpcd"
    "L /var/lib/dibbler - - - - /persist/dibbler"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  users.mutableUsers = false;
  users.users.nixos = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPSTOhvWnmozjnk82eW9yzb7Flty48PwsNTF+KItdv5w actions-user@github.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAKU7x1o6NPI/7AqwCaC8edvl80//2LgyVSV/3tIfb tie@xhyve"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFOq52CJ77uZJ7lDpRgODDMaO22PeHi1GB+rRyj7j+o1 tie@goro"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
  nix.trustedUsers = [ "@wheel" ];

  services.openssh.hostKeys = [{
    path = "/persist/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];
}
