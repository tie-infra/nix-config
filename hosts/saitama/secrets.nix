let
  recipients = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCZc4onME11xJIxAgCTInS4gLYr7dIzek3DsHsBguyN"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAKU7x1o6NPI/7AqwCaC8edvl80//2LgyVSV/3tIfb tie@xhyve"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFOq52CJ77uZJ7lDpRgODDMaO22PeHi1GB+rRyj7j+o1 tie@goro"
  ];
in { "factorio-server-settings.age".publicKeys = recipients; }
