{ dusk, ... }:
{
  imports = [
    ../../common
    ./services/chronicle.nix
    ./services/nginx.nix
  ];

  config.dusk = {
    chronicle = {
      inherit (dusk.profiles.nostr-relay)
        ownerPubkey
        name
        description
        url
        icon
        contact
        ;

      enable = true;
    };

    tor.enable = true;
  };
}
