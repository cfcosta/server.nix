let
  config = import ../config.nix;

  inherit (config.keys) users nodes;
in
{
  "dendrite.pem.age".publicKeys = users.cfcosta ++ nodes.matrix-servers;
  "dendrite.secret.age".publicKeys = users.cfcosta ++ nodes.matrix-servers;
  "dendrite-sliding-sync.secret.age".publicKeys = users.cfcosta ++ nodes.matrix-servers;
  "tor-ed25519.age".publicKeys = users.cfcosta ++ nodes.matrix-servers;
}
