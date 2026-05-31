{ config, pkgs, ... }:
let
  # Rendered by sops-nix to /run/secrets/rendered/ (mode 0400, owned by the
  # sing-box user) with the two Hysteria2 credentials substituted in. Kept out
  # of the world-readable /nix/store, which rules out services.sing-box.settings
  # (that renders to the store) -- hence the hand-written unit below.
  configFile = config.sops.templates."sing-box.json".path;
in
{
  # Cascade VPN relay (Moscow hop).
  #
  #   Mobile (Happ, VLESS/WS) --TLS--> Caddy :443 (relay.brim.su)
  #     --plain ws--> sing-box 127.0.0.1:18443
  #       --Hysteria2/UDP--> vpn.brim.su:443 --> internet
  #
  # To DPI the mobile leg looks like ordinary HTTPS to brim.su (which already
  # fronts many legitimate services). The Moscow -> vpn.brim.su hop is RU<->RU
  # Hysteria2 (salamander obfs), which mobile carriers do not throttle the way
  # they throttle the mobile<->abroad UDP/443 this is working around.

  # Dedicated unprivileged user (mirrors hosts/akane/xray.nix).
  users = {
    users.sing-box = {
      isSystemUser = true;
      group = config.users.groups.sing-box.name;
    };
    groups.sing-box = { };
  };

  # Server-to-server credentials (NOT handed to clients, unlike the VLESS UUID),
  # so they live in SOPS rather than inline. The values must be added to
  # secrets/brim.sops.yaml (keys hysteria2/moscow-auth and hysteria2/obfs-password)
  # before rebuilding, otherwise sops-nix activation fails.
  sops.secrets = {
    "hysteria2/moscow-auth" = {
      sopsFile = ../../secrets/brim.sops.yaml;
      restartUnits = [ "sing-box.service" ];
    };
    "hysteria2/obfs-password" = {
      sopsFile = ../../secrets/brim.sops.yaml;
      restartUnits = [ "sing-box.service" ];
    };
  };

  sops.templates."sing-box.json" = {
    owner = config.users.users.sing-box.name;
    restartUnits = [ "sing-box.service" ];
    content = builtins.toJSON {
      log = {
        level = "info";
        timestamp = true;
      };

      inbounds = [
        {
          type = "vless";
          tag = "vless-ws-in";
          listen = "127.0.0.1";
          listen_port = 18443;
          users = [
            # Public: handed to clients in the Happ URL, so it stays inline.
            { uuid = "1ea52fe2-2e51-4951-9b0c-4f8c16e47890"; }
          ];
          transport = {
            type = "ws";
            path = "/relay";
          };
        }
      ];

      outbounds = [
        {
          type = "hysteria2";
          tag = "hy2-out";
          server = "vpn.brim.su";
          server_port = 443;
          password = config.sops.placeholder."hysteria2/moscow-auth";
          obfs = {
            type = "salamander";
            password = config.sops.placeholder."hysteria2/obfs-password";
          };
          tls = {
            enabled = true;
            # vpn.brim.su has a valid Let's Encrypt cert -- verify normally.
            server_name = "vpn.brim.su";
          };
        }
        {
          type = "direct";
          tag = "direct";
        }
      ];

      # Everything exits through the Hysteria2 cascade. To bypass the hop for
      # specific destinations later, add route.rules that point at "direct".
      route = {
        final = "hy2-out";
      };
    };
  };

  systemd.services.sing-box = {
    description = "sing-box — cascade relay (Mobile → Moscow → vpn.brim.su)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      User = config.users.users.sing-box.name;
      Group = config.users.groups.sing-box.name;
      # Validate the rendered config (catches any sing-box schema mismatch in
      # this nixpkgs before the relay actually goes live).
      ExecStartPre = "${pkgs.sing-box}/bin/sing-box check -c ${configFile}";
      ExecStart = "${pkgs.sing-box}/bin/sing-box -c ${configFile} run";
      Restart = "on-failure";
      RestartSec = 3;
      LimitNOFILE = 1048576;

      # Hardening: sing-box only reads its config from /run and talks network;
      # it writes nothing to disk (logs go to the journal).
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      LockPersonality = true;
    };
  };

  # Front door: Caddy terminates TLS for relay.brim.su (automatic Let's Encrypt)
  # and reverse-proxies the WebSocket upgrade to sing-box. Dialing 127.0.0.1
  # explicitly (not "localhost") because sing-box binds the v4 loopback only.
  # This route is merged into the list in hosts/brim/caddy.nix (NixOS
  # concatenates them), so caddy.nix stays untouched -- same as akane/xray.nix.
  services.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ "relay.brim.su" ]; } ];
      terminal = true;
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "127.0.0.1:18443"; } ];
        }
      ];
    }
  ];
}
