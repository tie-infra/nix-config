{
  config,
  lib,
  pkgs,
  ...
}:
let
  mumblePort = 64738;
in
{
  networking.firewall = {
    allowedUDPPorts = [ mumblePort ];
    allowedTCPPorts = [ mumblePort ];
  };

  services.mumble-server = {
    enable = true;
    settings.globalSection = {
      bonjour = false; # TODO: use systemd dnssd configuration
      # Note: do not be fooled by the logs! Qt uses `0.0.0.0` instead of `::` as
      # a string representation for unspecified IP address, QHostAddress::Any,
      # but it is actually dual-stack.
      # https://doc.qt.io/qt-6/qhostaddress.html#toString
      # https://doc.qt.io/qt-6/qhostaddress.html#SpecialAddress-enum
      # In fact, setting address to `::` explicitly will enable IPv6-only mode.
      # This actually is reasonable behavior, albeit inconsistent with other
      # software.
      #host = "::";
      port = mumblePort;
      serverpassword = "{server_password}";
      channelname = ".+";
      bandwidth = 558000;
    };
  };

  systemd.services.mumble-server =
    let
      mumble-server-init =
        pkgs.writers.writePython3Bin "mumble-server-init"
          {
            makeWrapperArgs = [
              "--prefix"
              "PATH"
              ":"
              (lib.makeBinPath [
                config.services.mumble-server.package
              ])
            ];
          }
          ''
            import os
            import pathlib
            import shutil
            import sys

            template_config_file = pathlib.Path(os.environ["CONFIG_FILE"])
            rendered_config_file = pathlib.Path(os.environ["RENDERED_CONFIG_FILE"])
            credentials_directory = pathlib.Path(os.environ["CREDENTIALS_DIRECTORY"])

            server_password_file = credentials_directory / "server-password"
            superuser_password_file = credentials_directory / "superuser-password"

            rendered_config_file.write_text(
                template_config_file.read_text().format(
                    server_password=server_password_file.read_text(),
                )
            )

            print(os.environ["PATH"])
            print(shutil.which("mumble-server"))

            argv0 = "mumble-server"
            args = [
                argv0,
                "-fg",
                "-ini",
                rendered_config_file,
                "-readsupw",
            ]
            with superuser_password_file.open("rb", buffering=0) as f:
                os.dup2(f.fileno(), sys.stdin.fileno())
            os.execvp(argv0, args)
          '';
    in
    {
      environment.RENDERED_CONFIG_FILE = "%t/mumble-server/mumble-server.ini";
      serviceConfig = {
        ExecSearchPath = lib.mkBefore [ (lib.makeBinPath [ mumble-server-init ]) ];
        ExecStartPre = [ "mumble-server-init" ];
        ExecStart = lib.mkForce "mumble-server -fg -ini \${RENDERED_CONFIG_FILE}";
        RuntimeDirectory = "mumble-server";
        RuntimeDirectoryMode = "0700";
        LoadCredential = [
          "server-password:${config.sops.secrets."mumble-server/password".path}"
          "superuser-password:${config.sops.secrets."mumble-server/superuser-password".path}"
        ];
      };
    };

  sops.secrets = {
    "mumble-server/password" = {
      restartUnits = [ config.systemd.services.mumble-server.name ];
      sopsFile = ../../secrets/mumble-server.sops.yaml;
    };
    "mumble-server/superuser-password" = {
      restartUnits = [ config.systemd.services.mumble-server.name ];
      sopsFile = ../../secrets/mumble-server.sops.yaml;
    };
  };
}
