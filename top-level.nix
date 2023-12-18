{
  imports = [
    ./secrets

    ./hosts/akane
    ./hosts/bootstrap
    ./hosts/brim
    ./hosts/helsing
    ./hosts/hikari
    ./hosts/kazuma
    ./hosts/saitama

    ./parts/backports
    ./parts/base-system
    ./parts/btrfs-on-bcache
    ./parts/erase-your-darlings
    ./parts/installer
    ./parts/java-wrappers
    ./parts/jellyfin-wal-backport
    ./parts/machine-info
    ./parts/nix-flakes
    ./parts/nixos-with-system
    ./parts/services
    ./parts/trust-admins
  ];

  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixpkgs-fmt;

    minimalShells.direnv = with pkgs; [
      nixpkgs-fmt
      sops
      ssh-to-age
      go-task
    ];
  };
}
