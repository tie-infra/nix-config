{ rustPlatform
, btrfs-progs
}:
rustPlatform.buildRustPackage {
  name = "restore-btrfs";
  src = ./.;

  cargoHash = "sha256-tNHmHWIlpzwMKPyq0PcPberHCffU3mFyKt7gQDcHdIQ=";

  nativeBuildInputs = [ rustPlatform.bindgenHook ];
  buildInputs = [ btrfs-progs ];
}
