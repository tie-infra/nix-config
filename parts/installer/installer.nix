{ self, ... }:
{ lib, pkgs, modulesPath, ... }:
let
  # NB we do not use writeShellApplication since shellcheck fails to cross-compile.
  setup-disk = pkgs.writeScriptBin "setup-disk" (builtins.readFile ./setup-disk.sh);
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    self.nixosModules.nix-flakes
  ];

  networking.hostName = "installer";

  environment.systemPackages = [ setup-disk ];

  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
    extraConfig = ''
      LoginGraceTime 15s
      RekeyLimit default 30m
    '';
  };

  users.users.nixos.openssh.authorizedKeys.keys = self.lib.sshKeys.tie;

  isoImage = {
    # NixOS uses syslinux for legacy BIOS boot, and syslinux currently cannot be
    # cross-compiled from non-x86 platforms. As a workaround, we disable legacy
    # BIOS boot (note that USB boot is subset of BIOS boot).
    makeBiosBootable = lib.mkForce false;
    makeUsbBootable = lib.mkForce false;
    makeEfiBootable = lib.mkForce true;
  };
}
