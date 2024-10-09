{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOverride;
in
{
  config = mkIf config.services.postgresql.enable {
    services.postgresql = {
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
