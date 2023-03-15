_: _: {
  boot.initrd.availableKernelModules = [ "nvme" ];

  eraseYourDarlings =
    let disk = "SPCC_M.2_PCIe_SSD_27FF070C189700120672";
    in {
      bootDisk = "/dev/disk/by-id/nvme-${disk}-part1";
      rootDisk = "/dev/disk/by-id/nvme-${disk}-part2";
    };
}
