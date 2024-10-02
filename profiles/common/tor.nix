{
  config,
  dusk,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.dusk.tor;
in
{
  options.dusk.tor.enable = mkEnableOption "Enable exposing services under the Onion Network.";

  config = mkIf cfg.enable {
    services = {
      nginx.virtualHosts.${dusk.domain}.extraConfig = ''
        add_header Onion-Location http://trspv4gsa5irkrflbskyzwfo6vsj5h6i6zaelgc52hxmuoz6w6xpzbid.onion$request_uri;
      '';

      tor = {
        enable = config.services.nginx.enable;
        enableGeoIP = false;

        settings = {
          ClientUseIPv4 = false;
          ClientUseIPv6 = true;
          ClientPreferIPv6ORPort = true;
        };

        relay.onionServices.server = {
          version = 3;

          map = [
            {
              port = 80;

              target = {
                addr = "[::1]";
                port = 80;
              };
            }
            {
              port = 443;

              target = {
                addr = "[::1]";
                port = 443;
              };
            }
          ];
        };
      };
    };
  };
}
