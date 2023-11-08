final: prev: {
  # Enable WAL journal mode for SQLite.
  # See https://github.com/jellyfin/jellyfin/issues/10314
  jellyfin = prev.jellyfin.overrideAttrs ({ patches ? [ ], ... }: {
    patches = patches ++ [
      (final.fetchpatch {
        name = "jellyfin-sqlite-wal.patch";
        url = "https://github.com/jellyfin/jellyfin/pull/9044.patch";
        hash = "sha256-rnkaKjIxjmgxcQ1zHLDMmkzg0Sm5qcB5f03sCQ085vI=";
      })
      (final.fetchpatch {
        name = "jellyfin-sqlite-wal-followup.patch";
        url = "https://github.com/jellyfin/jellyfin/pull/9667.patch";
        hash = "sha256-StxRt8N58d/fk2WbMFT49Yu28/z7jXyadSY9Gliw7XA=";
      })
    ];
  });
}
