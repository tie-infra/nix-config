{ pkgs, ... }:
{
  minimalShells.direnv = with pkgs; [
    nixpkgs-fmt
    sops
    ssh-to-age
    go-task
  ];
}
