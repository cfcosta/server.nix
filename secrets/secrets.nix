let
  config = import ../config.nix;
  inherit (config.keys) users nodes;
in
{
  "tor-ed25519.age".publicKeys = users.cfcosta ++ nodes.server;
}
