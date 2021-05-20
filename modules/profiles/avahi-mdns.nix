{ config, lib, pkgs, ... }: {
  # Enable mDNS discovery.
  services.avahi.enable = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.addresses = true;
}
