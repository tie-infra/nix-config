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

  environment.systemPackages = [ setup-disk ] ++ (with pkgs; [
    # Useful for verifying that ECC is working.
    edac-utils
    dmidecode
  ]);

  services.openssh = {
    enable = true;
    # NB do not set startWhenNeeded, otherwise the hostKeys are not generated on
    # system startup. This breaks the manual setup procedure when connected to
    # monitor and keyboard without SSH and/or network access.
    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    extraConfig = ''
      LoginGraceTime 15s
      RekeyLimit default 30m
    '';
  };

  users.users.nixos.openssh.authorizedKeys.keys = with self.lib.sshKeys;
    tie ++ brim;
}
