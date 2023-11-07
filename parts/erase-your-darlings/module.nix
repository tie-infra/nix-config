# See https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html

{ lib, pkgs, config, ... }:
let
  cfg = config.eraseYourDarlings;
in
{
  options.eraseYourDarlings = {
    bootDisk = lib.mkOption {
      type = lib.types.str;
      example = "/dev/disk/by-uuid/CFF8-EF57";
      description = lib.mdDoc ''
        Boot disk device node path to use.
      '';
    };
    rootDisk = lib.mkOption {
      type = lib.types.str;
      example = "/dev/disk/by-uuid/0d0da679-fc37-4cd0-8098-6216a4e28d7d";
      description = lib.mdDoc ''
        Root disk device node path to use.
      '';
    };
    subvolumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "home" ];
      description = lib.mdDoc ''
        Additional subvolumes to mount, e.g. for persistent home directory.
      '';
    };

    persist = {
      openssh = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc ''
          Use SSH host key from persist subvolume.
        '';
      };

      machineId = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc ''
          Use /etc/machine-id from persist subvolume.
        '';
      };
    };
  };

  config = {
    boot.initrd.extraUtilsCommands = ''
      copy_bin_and_libs ${lib.getExe pkgs.btrfs-rollback}
    '';

    boot.initrd.extraUtilsCommandsTest = ''
      $out/bin/btrfs-rollback --help
    '';

    # NB we want to run after btrfs device scan, hence lib.mkAfter.
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      echo 'restoring root filesystem from blank snapshot...'
      btrfs-rollback \
        --device-path ${lib.escapeShellArg cfg.rootDisk} \
        --mountpoint /mnt \
        --subvolume root \
        --snapshot root-blank
    '';

    # FIXME: turns out this code wrongly assumed that compression can be enable
    # per subvolume or mountpoint. This is not true, see
    # https://btrfs.readthedocs.io/en/latest/btrfs-man5.html#btrfs-specific-mount-options
    # Also consider enabling user_subvol_rm_allowed. And enable block-group-tree
    # with btrfstune (or rebuild filesystem with block_group_tree feature). See
    # https://btrfs.readthedocs.io/en/latest/mkfs.btrfs.html#man-mkfs-filesystem-features
    fileSystems =
      let
        subvolumeFileSystems = lib.mapAttrs' (name: lib.nameValuePair "/${name}")
          (lib.genAttrs cfg.subvolumes (name: {
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

    environment.etc = lib.mkIf cfg.persist.machineId {
      "machine-id".source = "/persist/machine-id";
    };

    services = {
      openssh.hostKeys = lib.mkIf cfg.persist.openssh [{
        path = "/persist/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }];

      btrfs.autoScrub = {
        enable = true;
        fileSystems = [ "/" ];
      };
    };
  };
}
