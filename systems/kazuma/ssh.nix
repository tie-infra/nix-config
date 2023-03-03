{ self, ... }: lib: {
  imports = with self.nixosModules; [
    openssh
    persist-ssh
  ];

  users.users.nixos.openssh.authorizedKeys.keys = lib.sshAuthorizedKeys;
}
