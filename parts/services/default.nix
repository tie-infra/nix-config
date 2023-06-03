{
  flake.nixosModules.services = {
    imports = [
      ./jackett
      ./jellyfin
      ./sonarr
      ./transmission
    ];
  };
}
