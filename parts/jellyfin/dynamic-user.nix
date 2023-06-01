{ lib, config, ... }:
let
  cfg = config.services.jellyfin;
in
{
  options.services.jellyfin = {
    dynamicUser = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = lib.mdDoc ''
        Enable `DynamicUser` for systemd service. Setting options
        {option}`services.jellyfin.user` and {option}`services.jellyfin.user`
        has no effect when enabled.
      '';
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "video" "render" ];
      description = lib.mdDoc ''
        Additional groups for the systemd service.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.dynamicUser) {
    systemd.services.jellyfin = {
      serviceConfig = {
        DynamicUser = true;
        User = lib.mkForce null;
        Group = lib.mkForce null;
        SupplementaryGroups = cfg.extraGroups;
      };
    };

    # Set user and group to non-default value to avoid creating them.
    # See https://github.com/NixOS/nixpkgs/blob/58bf1f8bad92bea6fa0755926f517ca585f93986/nixos/modules/services/misc/jellyfin.nix#L110-L119
    services.jellyfin = {
      user = lib.mkForce "";
      group = lib.mkForce "";
    };
  };
}
