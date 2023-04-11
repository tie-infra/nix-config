_: _:
{ lib, config, modulesPath, ... }:
let cfg = config.eraseYourDarlings;
in with lib; {
  options.eraseYourDarlings = {
    bootDisk = mkOption {
      type = types.str;
      example = "/dev/disk/by-uuid/CFF8-EF57";
      description = mdDoc ''
        Boot disk device node path to use.
      '';
    };
    rootDisk = mkOption {
      type = types.str;
      example = "/dev/disk/by-uuid/0d0da679-fc37-4cd0-8098-6216a4e28d7d";
      description = mdDoc ''
        Root disk device node path to use.
      '';
    };
    subvolumes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "home" ];
      description = mdDoc ''
        Additional subvolumes to mount, e.g. for persistent home directory.
      '';
    };
  };

  config = {
    # See https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html
    boot.initrd.postDeviceCommands = mkBefore ''
      mkdir -p /mnt
      mount -t btrfs -o subvol=/ ${escapeShellArg cfg.rootDisk} /mnt
      btrfs subvolume list -o /mnt/root |
      cut -f9 -d' ' | while read subvolume; do
        echo "deleting /$subvolume subvolume..."
        btrfs subvolume delete "/mnt/$subvolume"
      done &&
      echo "deleting /root subvolume..." &&
      btrfs subvolume delete /mnt/root
      echo "restoring blank /root subvolume..."
      btrfs subvolume snapshot /mnt/root-blank /mnt/root
      umount /mnt
    '';

    fileSystems =
      let
        subvolumeFileSystems = mapAttrs' (name: nameValuePair "/${name}")
          (genAttrs cfg.subvolumes (name: {
            device = cfg.rootDisk;
            fsType = "btrfs";
            options = [ "subvol=${name}" "compress=zstd" ];
            neededForBoot = true;
          }));
      in
      subvolumeFileSystems // {
        "/boot" = {
          device = cfg.bootDisk;
          fsType = "vfat";
        };
        "/" = {
          device = cfg.rootDisk;
          fsType = "btrfs";
          options = [ "subvol=root" "compress=zstd" ];
        };
        "/nix" = {
          device = cfg.rootDisk;
          fsType = "btrfs";
          options = [ "subvol=nix" "compress-force=zstd" "noatime" ];
        };
        "/var" = {
          device = cfg.rootDisk;
          fsType = "btrfs";
          options = [ "subvol=var" "compress=zstd" ];
        };
        "/persist" = {
          device = cfg.rootDisk;
          fsType = "btrfs";
          options = [ "subvol=persist" "compress=zstd" ];
          neededForBoot = true;
        };
      };
  };
}
