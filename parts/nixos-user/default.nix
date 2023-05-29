{ self, ... }: {
  flake.nixosModules.nixos-user = { config, ... }: {
    services.getty.autologinUser = config.users.users.nixos.name;
    users.users.nixos = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = with config.users.groups;
        [ wheel.name ];
      openssh.authorizedKeys.keys = with self.lib.sshKeys;
        github-actions ++ tie ++ brim;
    };
  };
}
