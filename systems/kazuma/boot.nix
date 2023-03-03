{ self, ... }: _: {
  imports = with self.nixosModules; [
    erase-your-darlings-btrfs
    systemd-boot
  ];

  boot.initrd.availableKernelModules = [ "nvme" ];

  eraseYourDarlingsBtrfs =
    let disk = "SPCC_M.2_PCIe_SSD_27FF070C189700120672";
    in {
      bootDisk = "/dev/disk/by-id/nvme-${disk}-part1";
      rootDisk = "/dev/disk/by-id/nvme-${disk}-part2";
    };
}
