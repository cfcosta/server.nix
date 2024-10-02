{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkOverride;

  dendrite = config.dusk.dendrite;
  matrix-sliding-sync = config.dusk.matrix-sliding-sync;
in
{
  config = mkIf (dendrite.enable || matrix-sliding-sync.enable) {
    services.postgresql = {
      enable = true;
      enableJIT = true;
      enableTCPIP = true;

      package = pkgs.postgresql_16_jit;

      authentication = mkOverride 10 ''
        local all all trust

        host  all all 127.0.0.1/32 trust
        host  all all ::1/128 trust
      '';
    };
  };
}
