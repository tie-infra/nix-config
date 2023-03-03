{ self, ... }: _:
system:
let
  attr =
    if system != "x86_64-linux"
    then "installer-amd64/${system}"
    else "installer-amd64";
in
  self.nixosConfigurations.${attr}.config.system.build.isoImage or { }
