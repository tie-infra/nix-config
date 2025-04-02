_: prev: {
  sonarr = prev.sonarr.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches or [ ] ++ [ ./happy-eyeballs.patch ];
  });
}
