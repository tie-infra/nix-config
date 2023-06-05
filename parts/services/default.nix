{
  flake.nixosModules.services = {
    imports = [
      ./jackett
      ./jellyfin
      ./minio
      ./sonarr
      ./transmission
    ];
  };
}
