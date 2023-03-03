{ nixpkgs, ... }: _:
with nixpkgs.lib;
{ config, lib, modulesPath, ... }:
let
  bootDisk = config.eraseYourDaringsBtrfs.bootDisk;
  rootDisk = config.eraseYourDaringsBtrfs.rootDisk;
  subvolumes = config.eraseYourDaringsBtrfs.subvolumes;
in
{
  options.eraseYourDaringsBtrfs = {
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
      example = [ "home" ];
      description = mdDoc ''
        Subvolumes to mount, e.g. for persistent home directory.
      '';
    };
  };

  # See https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html
  boot.initrd.postDeviceCommands = mkBefore ''
    mkdir -p /mnt
    mount -t btrfs -o subvol=/ ${lib.escapeShellArg rootDisk} /mnt
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
        (genAttrs subvolumes (name: {
          device = rootDisk;
          fsType = "btrfs";
          options = [ "subvol=${name}" "compress=zstd" ];
          neededForBoot = true;
        }));
    in
    subvolumeFileSystems // {
      "/boot" = {
        device = bootDisk;
        fsType = "vfat";
      };
      "/" = {
        device = rootDisk;
        fsType = "btrfs";
        options = [ "subvol=root" "compress=zstd" ];
      };
      "/nix" = {
        device = rootDisk;
        fsType = "btrfs";
        options = [ "subvol=nix" "compress-force=zstd" "noatime" ];
      };
      "/persist" = {
        device = rootDisk;
        fsType = "btrfs";
        options = [ "subvol=persist" "compress=zstd" ];
        neededForBoot = true;
      };
    };
}
