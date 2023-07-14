{
  flake.nixosModules.services = {
    imports = [
      ./flood
      ./jackett
      ./jellyfin
      ./minio
      ./sonarr
      ./transmission
    ];
  };
}
