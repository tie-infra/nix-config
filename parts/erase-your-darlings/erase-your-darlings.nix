# See https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html

{ lib, pkgs, config, ... }:
let
  cfg = config.eraseYourDarlings;

  restoreBtrfs = pkgs.callPackage ./restore-btrfs { };
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
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      echo 'restoring root filesystem from blank snapshot...'
      ${lib.getExe restoreBtrfs} --device-path ${lib.escapeShellArg cfg.rootDisk}
    '';

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

    services.openssh.hostKeys = lib.mkIf cfg.persist.openssh [{
      path = "/persist/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };
}
