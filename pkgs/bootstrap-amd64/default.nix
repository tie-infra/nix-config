{ self, ... }: _:
system:
let
  attr =
    if system != "x86_64-linux"
    then "bootstrap-amd64/${system}"
    else "bootstrap-amd64";
in
  self.nixosConfigurations.${attr}.config.system.build.isoImage or { }
