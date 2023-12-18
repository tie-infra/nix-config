{
  sops = {
    log = [ "secretChanges" ]; # disable default keyImport log
    defaultSopsFile = ./secrets.yaml;
  };
}
