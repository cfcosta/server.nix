{
  config,
  dusk,
  lib,
  ...
}:
let
  inherit (builtins) toJSON;
  inherit (lib) mkIf;

  cfg = config.dusk.chronicle;

  nip05 = {
    names._ = dusk.nostr.hex;
    relays.${dusk.nostr.hex} = [
      "wss://nostr.${dusk.domain}"
      "wss://nostr.${dusk.tor.domain}"
    ];
  };

in
{
  config = mkIf cfg.enable {
    security.acme.certs."nostr.${dusk.domain}".email = dusk.email;

    services.nginx.virtualHosts = {
      ${dusk.domain} = {
        locations."/.well-known/nostr.json".extraConfig = ''
          default_type application/json;
          return 200 '${toJSON nip05}';
          add_header "Access-Control-Allow-Origin" *;
        '';
      };

      ${dusk.tor.domain} = {
        locations."/.well-known/nostr.json".extraConfig = ''
          default_type application/json;
          return 200 '${toJSON nip05}';
          add_header "Access-Control-Allow-Origin" *;
        '';
      };
    };
  };
}
