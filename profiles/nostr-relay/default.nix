{ dusk, ... }:
{
  imports = [
    ../../common
    ./services/chronicle.nix
    ./services/nginx.nix
  ];

  config.dusk = {
    chronicle = {
      enable = true;

      ownerPubkey = dusk.nostr.hex;
      name = "disconnect.capital";
      description = "The Nostr relay for the disconnect.capital peeps.";
      url = "nostr.${dusk.domain}";
      icon = "https://nostr.${dusk.domain}/static/";
      contact = "_@disconnect.capital";
    };

    tor.enable = true;
  };
}
