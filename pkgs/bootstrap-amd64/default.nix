{ self, ... }: _:
system:
let attr = "bootstrap-amd64/${system}";
in self.nixosConfigurations.${attr}.config.system.build.isoImage or { }
