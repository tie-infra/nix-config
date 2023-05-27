{ lib, ... }: {
  nix.settings.trusted-users = [ "@wheel" ];

  security.sudo = {
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  security.doas.wheelNeedsPassword = false;

  # See https://wiki.archlinux.org/title/Polkit#Globally
  security.polkit.extraConfig = ''
    /* Allow members of the wheel group to execute any actions
     * without password authentication, similar to "sudo NOPASSWD:"
     */
    polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    });
  '';
}
