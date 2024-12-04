{
  lib,
  stdenv,
  fetchFromGitHub,
  substituteAll,
  buildDotnetModule,
  dotnet-sdk_6,
  dotnet-aspnetcore_6,
  sqlite,
  ffmpeg,
  fetchYarnDeps,
  yarn,
  nodejs,
  fixup-yarn-lock,
  prefetch-yarn-deps,
}:
buildDotnetModule rec {
  pname = "sonarr";
  version = "4.0.5.1710";

  src = fetchFromGitHub {
    owner = "Sonarr";
    repo = "Sonarr";
    rev = "v${version}";
    hash = "sha256-bfpd1yiW+Ftq7sTic91wX3w92Q73RI7Ow5fDjt/Yu3s=";

    # passthru.fetch-deps and nuget-to-nix fail to generate deps.nix for
    # packages from third-party registries since NuGet.config is not in the
    # current working directory. As a workaround, until it is possible to pass
    # nuget config path to buildDotnetModule (that would be passed down to
    # fetch-deps and therefore nuget-to-nix), just slap a symlink to
    # the NuGet.config file in the current working directory. Also ensure that
    # the file exists to avoid errors during the build process.
    postFetch = ''
      test -f $out/src/NuGet.Config
      ln -s src/NuGet.Config $out
    '';
  };

  patches = [
    (substituteAll {
      src = ./buildprops.patch;
      copyrightYear = "2024";
      assemblyVersion = version;
      assemblyConfiguration = "main";
    })
  ];

  strictDeps = true;
  nativeBuildInputs = [
    nodejs
    yarn
    fixup-yarn-lock
    prefetch-yarn-deps

    # Looks like buildDotnetModule hooks are using propagatedBuildInputs for
    # dotnet-sdk and non-native package ends up in PATH? Put it here so it takes
    # precedence over hooks. This should probably be fixed in Nixpkgs though.
    # This fixes cross-compilation.
    dotnet-sdk
  ];

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = src + "/yarn.lock";
    hash = "sha256-dSZBifvUGJx5lj7C+Sj+kJprK8JG6SE5vg6+X6QdCZ8=";
  };

  postConfigure = ''
    yarn config --offline set yarn-offline-mirror $yarnOfflineCache
    fixup-yarn-lock yarn.lock
    yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive
    patchShebangs node_modules
  '';
  postBuild = ''
    yarn --offline run build --env production
  '';
  postInstall = ''
    rm $out/lib/sonarr/ffprobe
    ln -s ${lib.getExe' ffmpeg "ffprobe"} $out/lib/sonarr/ffprobe
    cp -a _output/UI $out/lib/sonarr/UI
  '';
  postFixup = ''
    ln -s Sonarr $out/bin/NzbDrone
  '';

  runtimeDeps = [ sqlite ];
  nugetDeps = ./deps.nix;
  dotnet-sdk = dotnet-sdk_6;
  dotnet-runtime = dotnet-aspnetcore_6;

  # Nixpkgs .NET build infrastructure uses globalization-invariant mode that
  # breaks a lot of tests when run on Darwin. Instead of trying to disable them,
  # just do not run tests. See also https://github.com/NixOS/nixpkgs/pull/217587
  doCheck = !stdenv.hostPlatform.isDarwin;

  executables = [ "Sonarr" ];

  projectFile = [
    "src/NzbDrone.Console/Sonarr.Console.csproj"
    "src/NzbDrone.Mono/Sonarr.Mono.csproj"
  ];

  testProjectFile = [
    "src/NzbDrone.Api.Test/Sonarr.Api.Test.csproj"
    "src/NzbDrone.Common.Test/Sonarr.Common.Test.csproj"
    "src/NzbDrone.Core.Test/Sonarr.Core.Test.csproj"
    "src/NzbDrone.Host.Test/Sonarr.Host.Test.csproj"
    "src/NzbDrone.Libraries.Test/Sonarr.Libraries.Test.csproj"
    "src/NzbDrone.Mono.Test/Sonarr.Mono.Test.csproj"
    "src/NzbDrone.Test.Common/Sonarr.Test.Common.csproj"
  ];

  dotnetFlags = [
    "--property:TargetFramework=net6.0"
    "--property:EnableAnalyzers=false"
  ];

  # Skip manual, integration, automation and platform-dependent tests.
  dotnetTestFlags = [
    "--filter:${
      lib.concatStringsSep "&" [
        "TestCategory!=ManualTest"
        "TestCategory!=IntegrationTest"
        "TestCategory!=AutomationTest"

        # setgid tests
        "FullyQualifiedName!=NzbDrone.Mono.Test.DiskProviderTests.DiskProviderFixture.should_preserve_setgid_on_set_folder_permissions"
        "FullyQualifiedName!=NzbDrone.Mono.Test.DiskProviderTests.DiskProviderFixture.should_clear_setgid_on_set_folder_permissions"

        # we do not set application data directory during tests (i.e. XDG data directory)
        "FullyQualifiedName!=NzbDrone.Mono.Test.DiskProviderTests.FreeSpaceFixture.should_return_free_disk_space"

        # attempts to read /etc/*release and fails since it does not exist
        "FullyQualifiedName!=NzbDrone.Mono.Test.EnvironmentInfo.ReleaseFileVersionAdapterFixture.should_get_version_info"

        # fails to start test dummy because it cannot locate .NET runtime for some reason
        "FullyQualifiedName!=NzbDrone.Common.Test.ProcessProviderFixture.Should_be_able_to_start_process"
        "FullyQualifiedName!=NzbDrone.Common.Test.ProcessProviderFixture.kill_all_should_kill_all_process_with_name"

        # makes real HTTP requests
        "FullyQualifiedName!~NzbDrone.Core.Test.TvTests.RefreshEpisodeServiceFixture"
        "FullyQualifiedName!~NzbDrone.Core.Test.UpdateTests.UpdatePackageProviderFixture"
      ]
    }"
  ];

  meta = {
    description = "Smart PVR for newsgroup and bittorrent users";
    homepage = "https://sonarr.tv";
    license = lib.licenses.gpl3Only;
    maintainers = [ lib.maintainers.tie ];
    mainProgram = "Sonarr";
    platforms = dotnet-sdk.meta.platforms;
  };
}
