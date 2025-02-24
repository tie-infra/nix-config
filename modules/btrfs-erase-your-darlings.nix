# See https://mt-caret.github.io/blog/2020-06-29-optin-state.html
# See https://notthebe.ee/blog/nixos-ephemeral-zfs-root

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.profiles.btrfs-erase-your-darlings;
  script = ''
    echo 'restoring root filesystem from blank snapshot...'
    btrfs-rollback \
      --device-path ${lib.escapeShellArg cfg.rootDisk} \
      --mountpoint /mnt \
      --subvolume root \
      --snapshot root-blank
  '';
in
{
  options.profiles.btrfs-erase-your-darlings = {
    enable = lib.mkEnableOption "Erase Your Darlings for Btrfs";

    bootDisk = lib.mkOption {
      type = lib.types.str;
      example = "/dev/disk/by-uuid/CFF8-EF57";
      description = ''
        Boot disk device node path to use.
      '';
    };
    rootDisk = lib.mkOption {
      type = lib.types.str;
      example = "/dev/disk/by-uuid/0d0da679-fc37-4cd0-8098-6216a4e28d7d";
      description = ''
        Root disk device node path to use.
      '';
    };
    subvolumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "home" ];
      description = ''
        Additional subvolumes to mount, e.g. for persistent home directory.
      '';
    };

    persist = {
      openssh = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Use SSH host key from persist subvolume.
        '';
      };

      machineId = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Use /etc/machine-id from persist subvolume.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.systemd = {
      storePaths = [ pkgs.btrfs-rollback ];
      services.btrfs-rollback = {
        description = "Rollback root filesystem";

        path = [ pkgs.btrfs-rollback ];
        inherit script;

        wants = [ "systemd-udev-settle.service" ];
        after = [
          "systemd-udev-settle.service"
          "systemd-modules-load.service"
          "systemd-ask-password-console.service"
        ];
        conflicts = [ "shutdown.target" ];
        before = [
          "sysroot.mount"
          "shutdown.target"
        ];
        wantedBy = [ "initrd.target" ];

        unitConfig = {
          DefaultDependencies = false;
        };

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    };

    boot.initrd = {
      extraUtilsCommands = lib.mkIf (!config.boot.initrd.systemd.enable) ''
        copy_bin_and_libs ${lib.getExe pkgs.btrfs-rollback}
      '';
      # NB we want to run after btrfs device scan, hence lib.mkAfter.
      postDeviceCommands = lib.mkIf (!config.boot.initrd.systemd.enable) (lib.mkAfter script);
    };

    # FIXME: turns out this code wrongly assumed that compression can be enable
    # per subvolume or mountpoint. This is not true, see
    # https://btrfs.readthedocs.io/en/latest/btrfs-man5.html#btrfs-specific-mount-options
    # Also consider enabling user_subvol_rm_allowed. And enable block-group-tree
    # with btrfstune (or rebuild filesystem with block_group_tree feature). See
    # https://btrfs.readthedocs.io/en/latest/mkfs.btrfs.html#man-mkfs-filesystem-features
    fileSystems =
      let
        subvolumeFileSystems = lib.mapAttrs' (name: lib.nameValuePair "/${name}") (
          lib.genAttrs cfg.subvolumes (name: {
            device = cfg.rootDisk;
            fsType = "btrfs";
            options = [
              "subvol=${name}"
              "compress=zstd"
            ];
            neededForBoot = true;
          })
        );
      in
      subvolumeFileSystems
      // {
        "/boot" = {
          device = cfg.bootDisk;
          fsType = "vfat";
          options = [
            "dmask=0007"
            "fmask=0007"
            "noatime"
          ];
        };
        "/" = {
          device = cfg.rootDisk;
          fsType = "btrfs";
          options = [
            "subvol=root"
            "compress=zstd"
          ];
        };
        "/nix" = {
          device = cfg.rootDisk;
          fsType = "btrfs";
          options = [
            "subvol=nix"
            "compress-force=zstd"
            "noatime"
          ];
        };
        "/var" = {
          device = cfg.rootDisk;
          fsType = "btrfs";
          options = [
            "subvol=var"
            "compress=zstd"
          ];
        };
        "/persist" = {
          device = cfg.rootDisk;
          fsType = "btrfs";
          options = [
            "subvol=persist"
            "compress=zstd"
          ];
          neededForBoot = true;
        };
      };

    environment.etc = lib.mkIf cfg.persist.machineId { "machine-id".source = "/persist/machine-id"; };

    services.openssh.settings.HostKey = lib.mkIf cfg.persist.openssh "/persist/ssh/ssh_host_ed25519_key";

    services.btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/" ];
    };
  };
}
