{ lib, pkgs, modulesPath, ... }:
let
  # NB we do not use writeShellApplication since shellcheck fails to cross-compile.
  setup-disk = pkgs.writeScriptBin "setup-disk" (builtins.readFile ./setup-disk.sh);
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # Cross-compilation is broken. Seems to be fixed in 23.11? Will have to check
  # once it is released.
  documentation.nixos.enable = lib.mkForce false;

  networking = {
    hostName = "installer";
    useDHCP = true;
  };

  environment.systemPackages = [ setup-disk ] ++ (with pkgs; [
    # Useful for verifying that ECC is working.
    edac-utils
    dmidecode
  ]);

  services.openssh = {
    # Always start SSH to generate host keys that are used by the setup-disk script.
    # FIXME: generate keys if the file does not exist instead.
    startWhenNeeded = lib.mkForce false;
    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  # See https://github.com/NixOS/nixpkgs/blob/9cfaa8a1a00830d17487cb60a19bb86f96f09b27/nixos/modules/profiles/installation-device.nix#LL52C1-L67C1
  services.getty.helpLine = lib.mkForce ''
    The "nixos" and "root" accounts have empty passwords.

    To set up the disk for installation, type `sudo setup-disk /dev/sda` where
    `/dev/sda` is the target disk. Further instructions are printed on success.
  '';
}
