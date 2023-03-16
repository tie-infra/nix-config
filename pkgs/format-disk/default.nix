{ nixpkgs, ... }: lib: system:
lib.crossDerivation system lib.exposedSystems (targetSystem:
with lib.nixpkgsCross system targetSystem;
writeShellApplication {
  name = "format-disk";
  text = builtins.readFile ./format-disk.sh;
  runtimeInputs = [
    util-linux # mount, mountpoint
    coreutils # mkdir, cp
    parted
    btrfs-progs # mkfs.btrfs, btrfs
    dosfstools # mkfs.vfat
  ];
})
