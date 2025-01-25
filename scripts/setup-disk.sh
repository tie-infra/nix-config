#!/bin/sh
set -eu

echoerr() {
	echo "$@" >&2
}

if mountpoint -q /mnt; then
	echoerr "something is mounted at /mnt, refusing to run"
	exit 1
fi

cleanup() {
	if [ $? = 0 ]; then
		# Do nothing on success.
		return
	fi

	if ! mountpoint -q /mnt; then
		return
	fi
	if ! umount --recursive /mnt; then
		echoerr
		echoerr "========================== WARNING =========================="
		echoerr "FAILED TO UNMOUNT INSTALLATION TARGET, MANUAL ACTION REQUIRED"
		echoerr "============================================================="
		echoerr
	fi
}
trap cleanup EXIT

if [ $# != 1 ]; then
	echoerr "usage: setup-disk <device>"
	exit 1
fi

disk=$1
subvolumes="persist nix var"

boot=/dev/disk/by-partlabel/efi
root=/dev/disk/by-partlabel/nix

if test ! -b "$disk"; then
	echoerr "not a block device: $disk"
	exit 1
fi

echo "creating disk partitions"

# Create an empty partition table and ensure that old partitions do not exist.
parted --script -- "$disk" \
	mklabel gpt
if test \( -b "$boot" -o -b "$root" \); then
	echoerr "failed to create an empty partition table"
	exit 1
fi
parted --script -- "$disk" \
	mkpart efi fat32 1MiB 1GiB \
	mkpart nix btrfs 1GiB 100% \
	set 1 boot on

# Create a small partition for legacy BIOS boot compatibility if we are not on
# an EFI system. This is mainly used for GRUB installation and may be safely
# removed if the underlying platform is upgraded for UEFI support (e.g. using
# DUET from OpenCore).
#
# https://upload.wikimedia.org/wikipedia/commons/4/45/GNU_GRUB_components.svg
# https://gnu.org/software/grub/manual/grub/html_node/BIOS-installation.html#GPT
if test ! -d /sys/firmware/efi; then
	parted --script --align minimal -- "$disk" \
		mkpart bios 0 1MiB \
		set 3 bios_grub on
fi

# Give some time for udev to create device nodes.
udevadm settle || sleep 1
if test ! \( -b "$boot" -a -b "$root" \); then
	echoerr "failed to create partitions"
	exit 1
fi

echo "creating file systems"
mkfs.vfat -F 32 -n ESP "$boot"
mkfs.btrfs -f -L NixOS "$root"

echo "creating subvolumes"
mount -t btrfs "$root" /mnt
btrfs subvolume create /mnt/root
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
for subvolume in $subvolumes; do
	btrfs subvolume create /mnt/"$subvolume"
done
umount /mnt

echo "mounting file systems"
mount -o subvol=root,compress=zstd,noatime "$root" /mnt
for subvolume in $subvolumes; do
	mkdir /mnt/"$subvolume"
	mount -t btrfs -o subvol="$subvolume",compress=zstd,noatime "$root" /mnt/"$subvolume"
done
mkdir /mnt/boot
mount -t vfat -o dmask=0007,fmask=0007,noatime "$boot" /mnt/boot

echo "copying machine-id and SSH host key"
cp -a /etc/machine-id /mnt/persist/machine-id
mkdir /mnt/persist/ssh && chmod u=rwx,g=rx,o= /mnt/persist/ssh
cp -a /etc/ssh/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_ed25519_key /mnt/persist/ssh/

# TODO: detect current system and suggest appropriate bootstrap configuration.
echo
echo "Success! To install NixOS, run"
echo "  sudo nixos-install --no-channel-copy --no-root-password --flake github:tie-infra/nix-config#bootstrap-x86-64"
echo "and reboot"
exit 0
