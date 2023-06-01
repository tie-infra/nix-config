self: super: {
  jellyfin = super.jellyfin.overrideAttrs (prev: {
    patches = (prev.patches or [ ]) ++ [ ./enable-ipv6.patch ];
  });
}
