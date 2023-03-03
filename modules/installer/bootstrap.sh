#!/bin/sh
set -eu

if mountpoint -q /mnt; then
	echo "something is mounted at /mnt, refusing to run" >&2
	exit 1
fi

cleanup() {
	if [ $? = 0 ]; then
		return
	fi
	if ! mountpoint -q /mnt; then
		return
	fi
	if ! umount /mnt; then
		echo "FAILED TO UNMOUNT INSTALLATION TAGET, MANUAL ACTION REQUIRED" >&2
	fi
}
trap cleanup EXIT

if [ $# != 1 ]; then
	echo "usage: sh /iso/bootstrap.sh <device>" >&2
	exit 1
fi

disk=$1
subvolumes='persist nix'

if test ! -b "$disk"; then
	echo "not a block device: $disk" >&2
	exit 1
fi

echo "creating disk partitions"
sfdisk "$disk" </iso/sfdisk.dump

# Give some time to udev to create device nodes.
sleep 1

boot=/dev/disk/by-partlabel/efi
root=/dev/disk/by-partlabel/nix
if test ! \( -b "$boot" -a -b "$root" \); then
	echo "failed to create partions" >&2
	exit 1
fi

echo "creating file systems"
mkfs.vfat -n ESP "$boot"
mkfs.btrfs -f -L NixOS "$root"

echo "creating subvolumes"
mount -t btrfs "$root" /mnt
btrfs subvolume create /mnt/root
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
for subvolume in $subvolumes; do
	btrfs subvolume create /mnt/$subvolume
done
umount /mnt

echo "mounting file systems"
mount -o subvol=root,compress=zstd,noatime "$root" /mnt
for subvolume in $subvolumes; do
	mkdir /mnt/$subvolume
	mount -t btrfs -o subvol=$subvolume,compress=zstd,noatime "$root" /mnt/$subvolume
done
mkdir /mnt/boot
mount -t vfat "$boot" /mnt/boot

echo "copying machine-id and SSH host key"
cp -a /etc/machine-id /mnt/persist/machine-id
mkdir /mnt/persist/ssh && chmod u=rwx,g=rx,o= /mnt/persist/ssh
cp -a /etc/ssh/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_ed25519_key /mnt/persist/ssh/

# TODO: detect current system and suggest appropriate bootstrap configuration.
echo
echo "Success! To install NixOS, run"
echo "  sudo nixos-install --no-root-password --flake github:tie-infra/nix-config#bootstrap-amd64"
echo "and reboot"
exit 0
