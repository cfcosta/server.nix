let
  config = import ../config.nix;

  inherit (config.keys) cfcosta;
in
{
  "dendrite.pem.age".publicKeys = cfcosta;
  "dendrite.secret.age".publicKeys = cfcosta;
}
