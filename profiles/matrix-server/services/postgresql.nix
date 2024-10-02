{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;

  dendrite = config.dusk.dendrite;
  matrix-sliding-sync = config.dusk.matrix-sliding-sync;
in
{
  config = mkIf (dendrite.enable || matrix-sliding-sync.enable) {
    services.postgresql = {
      enable = true;
      enableJIT = true;
      enableTCPIP = false;

      package = pkgs.postgresql_16_jit;

      authentication = ''
        local all all trust
      '';
    };
  };
}
