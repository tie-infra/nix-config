# Set noop scheduler for zfs partitions
#
# See https://gist.github.com/mx00s/ea2462a3fe6fdaa65692fe7ee824de3e#gistcomment-3445180

{ ... }: {
  services.udev.extraRules = ''
    KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
  '';
}
