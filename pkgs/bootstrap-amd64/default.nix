{ self, ... }: _:
system:
# Cross-compilation for syslinux (used for BIOS legacy boot) fails. Building
# succeeds without it but the resulting ISO doesn’t boot in EFI mode. As a
# workaround, we do not expose this package on non-x86 systems.
if system != "x86_64-linux" then {} else {
  default = self.nixosConfigurations.bootstrap-amd64.config.system.build.isoImage;
}
