{ inputs, ... }: {
  flake.nixosModules.backports = {
    # nixos/networkd: allow state ranges in RequiredForOnline
    # https://github.com/NixOS/nixpkgs/pull/242191
    imports = [ (inputs.nixpkgs-backport-242191 + "/nixos/modules/system/boot/networkd.nix") ];
    disabledModules = [ "system/boot/networkd.nix" ];
  };

  flake.overlays.backports = final: prev: {
    # libgdiplus: 6.0.5 -> 6.1
    # https://github.com/NixOS/nixpkgs/pull/236930
    libgdiplus = final.callPackage (inputs.nixpkgs-unstable + "/pkgs/development/libraries/libgdiplus/default.nix") {
      inherit (final.darwin.apple_sdk.frameworks) Carbon;
    };

    # edac-utils: unstable-2015-01-07 -> unstable-2023-01-30
    # https://github.com/NixOS/nixpkgs/pull/234603
    edac-utils = final.callPackage (inputs.nixpkgs-unstable + "/pkgs/os-specific/linux/edac-utils/default.nix") { };

    # pufferpanel: build frontend from source
    # https://github.com/NixOS/nixpkgs/pull/234124
    pufferpanel = final.callPackage (inputs.nixpkgs-unstable + "/pkgs/servers/pufferpanel/default.nix") { };
  };
}
