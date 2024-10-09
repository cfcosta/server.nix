{ dusk, ... }:
{
  imports = [
    ../../common
    ./services/chronicle.nix
    ./services/nginx.nix
  ];

  config.dusk = {
    chronicle = dusk.nostr // {
      enable = true;
    };

    tor.enable = true;
  };
}
