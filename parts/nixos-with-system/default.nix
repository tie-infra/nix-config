{ self, inputs, lib, withSystem, ... }: {
  _module.args.nixosWithSystem = system: hostConfigurations:
    withSystem system ({ pkgs, ... }: lib.nixosSystem {
      modules = hostConfigurations ++ [
        inputs.sops-nix.nixosModules.sops
        # Avoid re-evaluating Nixpkgs.
        inputs.nixpkgs.nixosModules.readOnlyPkgs
        { nixpkgs.pkgs = pkgs; }
      ] ++ (with self.nixosModules; [
        base-system
        btrfs-on-bcache
        erase-your-darlings
        machine-info
        nix-flakes
        secrets
        services
        trust-admins
      ]);
    });
}
