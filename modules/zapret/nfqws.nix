{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkPackageOption
    ;
  inherit (lib.types)
    attrsOf
    port
    submodule
    ;

  inherit (import ./common.nix { inherit lib pkgs; })
    instanceModule
    ;

  cfg = config.services.nfqws;

  nfqwsInstanceModule = {
    imports = [ instanceModule ];
    options = {
      settings = mkOption {
        type = submodule {
          options.qnum = mkOption {
            type = port;
            description = ''
              Netfilter queue number.
            '';
          };
        };
      };
      profiles = mkOption {
        type = attrsOf (submodule {
          options.settings = mkOption {
            example = {
              dpi-desync = "fake";
              dpi-desync-ttl = 1;
              hostlist-auto = "hosts.txt";
            };
          };
        });
        example = {
          "50-https".settings = {
            filter-l7 = "tls,quic";
            dpi-desync = "fake";
            dpi-desync-ttl = 4;
            hostlist-auto = "hosts.txt";
            hostlist-auto-fail-threshold = 1;
          };
          "99-known".settings = {
            dpi-desync = "fakeknown";
            dpi-desync-ttl = 4;
            dpi-desync-repeats = 6;
          };
        };
      };
    };
    config = {
      _module.args.service = {
        name = "nfqws";
        inherit (cfg) package;
      };
    };
  };
in
{
  options.services.nfqws = {
    enable = mkEnableOption "nfqws service";
    package = mkPackageOption pkgs "zapret" { };
    instances = mkOption {
      type = attrsOf (submodule nfqwsInstanceModule);
      default = { };
      description = ''
        nfqws service instances.
      '';
    };
  };
}
