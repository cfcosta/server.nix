{
  config,
  dusk,
  lib,
  ...
}:
let
  inherit (builtins) toJSON;
  inherit (lib) mapAttrs mkIf;

  cfg = config.dusk.chronicle;
  inherit (dusk.profiles.nostr-relay) ownerPubkey;

  nip05 = {
    names = {
      _ = ownerPubkey;
    } // mapAttrs (_: user: user.pubkey) dusk.profiles.nostr-relay.users;

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
