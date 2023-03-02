_: _:
{
  # Enable SSH access.
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.kbdInteractiveAuthentication = false;
  services.openssh.extraConfig = ''
    LoginGraceTime 15s
    RekeyLimit default 30m
  '';
}
