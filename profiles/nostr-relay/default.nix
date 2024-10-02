{ dusk, ... }:
{
  imports = [
    ../common
    ../common/nginx.nix
    ./services/chronicle.nix
  ];

  config.dusk.chronicle = {
    enable = true;

    ownerPubkey = "cfa3df9203c440a5b94b1f863094e683412ce9d422a7f99c5346e43fe2001d92";
    name = "Disconnect Nostr Relay";
    description = "The Nostr relay for the disconnect.ventures peeps.";
    url = "nostr.${dusk.domain}";
    icon = "";
    contact = "_@disconnect.capital";
  };
}
