{ config, ... }:
{
  sops = {
    log = [ "secretChanges" ]; # disable default keyImport log
    age.sshKeyPaths = [ config.services.openssh.settings.HostKey ];
  };
}
