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
    age.secrets = {
      tor-secret-key = {
        file = dusk.secrets."tor-ed25519".path;
        mode = "0600";
        owner = "tor";
        path = "/var/lib/tor/onion/server/hs_ed25519_secret_key";
      };
    };

    services = {
      nginx.virtualHosts.${dusk.domain}.extraConfig = ''
        add_header Onion-Location http://${dusk.tor.domain}$request_uri;
      '';

      tor = {
        enable = config.dusk.tor.enable;
        enableGeoIP = false;

        settings = {
          ClientUseIPv4 = false;
          ClientUseIPv6 = true;
          ClientPreferIPv6ORPort = true;
        };

        relay.onionServices.server = {
          version = 3;
          secretKey = config.age.secrets.tor-secret-key.path;

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
