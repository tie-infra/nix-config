let
  recipients = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDiWJmsj22woegXiWRA7GJ7guA/RHdksA1yBDpkgJ+dp nixos@kazuma.tie.rip"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAKU7x1o6NPI/7AqwCaC8edvl80//2LgyVSV/3tIfb tie@xhyve"
  ];
in
{
  "pufferpanel-client-secret.age".publicKeys = recipients;
}
