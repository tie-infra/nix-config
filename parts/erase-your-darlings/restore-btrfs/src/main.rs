use anyhow::{Context, Result};
use clap::{Parser, ValueHint};
use libbtrfsutil::{create_snapshot, delete_subvolume, CreateSnapshotFlags, DeleteSubvolumeFlags};
use nix::mount::{mount, umount, MsFlags};
use std::fs::create_dir_all;
use std::path::{Path, PathBuf};

#[derive(Parser, Debug)]
struct Args {
    /// Btrfs device path to mount.
    #[clap(short, long, value_hint = ValueHint::FilePath)]
    device_path: PathBuf,

    /// Mount options for the btrfs filesystem.
    #[clap(short, long)]
    options: Option<PathBuf>,

    /// Temporary mountpoint for btrfs filesystem.
    #[clap(short, long, value_hint = ValueHint::DirPath, default_value = "/mnt")]
    mountpoint: PathBuf,

    /// Btrfs subvolume to delete recursively.
    #[clap(short, long, default_value = "root")]
    subvolume: PathBuf,

    /// Btrfs snapshot to restore subvolume from.
    #[clap(short, long, default_value = "root-blank")]
    snapshot: PathBuf,
}

fn main() -> Result<()> {
    let args = Args::parse();

    create_dir_all(&args.mountpoint).context("Failed to create directory for filesystem mount")?;

    mount(
        Some(&args.device_path),
        &args.mountpoint,
        Some("btrfs"),
        MsFlags::empty(),
        args.options.as_ref(),
    )
    .context("Failed to mount filesystem")?;

    let result = restore_snapshot(&args.mountpoint, &args.subvolume, &args.snapshot);
    unmount(&args.mountpoint);
    result
}

fn restore_snapshot(mountpoint: &Path, subvolume: &Path, snapshot: &Path) -> Result<()> {
    let subvolume_path = mountpoint.join(subvolume);
    let snapshot_path = mountpoint.join(snapshot);

    delete_subvolume(&subvolume_path, DeleteSubvolumeFlags::RECURSIVE)
        .context("Failed to recursively delete subvolume")?;

    create_snapshot(
        snapshot_path,
        subvolume_path,
        CreateSnapshotFlags::RECURSIVE,
        None,
    )
    .context("Failed to recursively restore snapshot")
}

fn unmount(mountpoint: &Path) {
    let result = umount(mountpoint).context("Failed to unmount filesystem");
    if let Err(e) = result {
        eprintln!("{}", e);
    }
}
