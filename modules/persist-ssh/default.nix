_: _:
let path = "/persist/ssh"; in {
  systemd.tmpfiles.rules = [
    # mkdir -p
    "d ${path} - - - - -"
    # chmod u=rwx,g=rx,o=
    "z ${path} 0750 - - - -"
  ];
  services.openssh.hostKeys = [{
    path = "${path}/ssh_host_ed25519_key";
    type = "ed25519";
  }];
}
