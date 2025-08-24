{
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  # NB we do not use writeShellApplication since shellcheck fails to cross-compile.
  setup-disk = pkgs.writeScriptBin "setup-disk" (builtins.readFile ../scripts/setup-disk.sh);
in
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  # Installer profile causes issues with readOnlyPkgs module.
  # https://github.com/NixOS/nixpkgs/blob/7dd001f3e20243d8df1c1f2b7268dd259804fc1e/nixos/modules/profiles/installation-device.nix#L130-L138
  nixpkgs.overlays = lib.mkForce [ ];

  # Fails with the following error unless we disable mdadm:
  #
  #  trace: warning: mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash.
  #
  # Perhaps that would be fixed in future NixOS versions, but for now we don’t
  # need software RAID.
  boot.swraid.enable = lib.mkForce false;

  networking = {
    hostName = "installer";
    useDHCP = true;
  };

  environment.systemPackages = [
    setup-disk
  ]
  ++ (with pkgs; [
    # Useful for verifying that ECC is working.
    edac-utils
    dmidecode
  ]);

  services.openssh.hostKeys = [
    {
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  # See https://github.com/NixOS/nixpkgs/blob/9cfaa8a1a00830d17487cb60a19bb86f96f09b27/nixos/modules/profiles/installation-device.nix#LL52C1-L67C1
  services.getty.helpLine = lib.mkForce ''
    The "nixos" and "root" accounts have empty passwords.

    To set up the disk for installation, type `sudo setup-disk /dev/sda` where
    `/dev/sda` is the target disk. Further instructions are printed on success.
  '';
}
