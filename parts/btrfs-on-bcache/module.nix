{ lib, utils, config, ... }:
let
  cfg = config.btrfsOnBcache;

  # See https://github.com/openlab-aux/vuizvui/commit/15008e69542774c441e388ad4c2e28a2d27f9ba0
  # and https://github.com/openlab-aux/vuizvui/commit/532daa8a52c0d3b9637177ae26f4b149f8c64c10
  #
  # FIXME: use filesystem path from config.services.btrfs.autoScrub.fileSystems
  # instead of disabling caching for all bcache devices. That is, we want to
  # list underlying btrfs devices that use bcache and temporarily disable
  # caching for them. In addition to that, we also need to restore the cache
  # mode on boot in case of power failure during scrub process. Sadly,
  # libbtrfsutil exposes a limited subset of high-level operations on the
  # filesystem. However, btrfs-progs supports JSON for some commands, e.g.
  # `btrfs --format=json device stats /`.
  bcacheStart = fs: ''
    for i in /sys/block/bcache[0-9]*/bcache/cache_mode; do
      echo writearound > "$i"
    done
  '';
  bcacheStop = fs: ''
    for i in /sys/block/bcache[0-9]*/bcache/cache_mode; do
      echo none > "$i"
    done
  '';

  # See https://github.com/NixOS/nixpkgs/blob/9034b46dc4c7596a87ab837bb8a07ef2d887e8c7/nixos/modules/tasks/filesystems/btrfs.nix#L104-L144
  # for the services.btrfs.autoScrub module implementation.
  btrfsScrubUnitName = fs: "btrfs-scrub-${utils.escapeSystemdPath fs}";
  btrfsScrubHooks = fs: {
    preStart = bcacheStop fs;
    postStop = bcacheStart fs;
  };

in
{
  options.btrfsOnBcache = {
    enable = lib.mkEnableOption (lib.mdDoc "tweaks for btrfs on bcache");
  };

  config = lib.mkIf (cfg.enable) {
    # Inject preStart/postStart for activating/deactivating bcache to the scrub
    # services, so we don’t get large amounts of nonsense on the caching device.
    systemd.services = lib.mkIf (config.services.btrfs.autoScrub.enable)
      (lib.mapAttrs' (fs: lib.nameValuePair (btrfsScrubUnitName fs))
        (lib.genAttrs config.services.btrfs.autoScrub.fileSystems btrfsScrubHooks));
  };
}
