{
  config,
  dusk,
  lib,
  ...
}:
let
  inherit (builtins) toJSON;
  inherit (lib) mapAttrs mapAttrs' mkIf;

  cfg = config.dusk.chronicle;

  nip05 = {
    names = mapAttrs (_: user: user.pubkey) dusk.profiles.nostr-relay.users;

    relays = mapAttrs' (_: user: {
      name = user.pubkey;
      value = [
        "wss://nostr.${dusk.domain}"
        "wss://nostr.${dusk.tor.domain}"
      ];
    }) dusk.profiles.nostr-relay.users;
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
