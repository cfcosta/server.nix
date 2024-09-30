{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;

  cfg = config.dusk.dendrite;
in
{
  config = mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      enableJIT = true;
      enableTCPIP = false;

      package = pkgs.postgresql_16_jit;

      authentication = ''
        local ${cfg.database.name} ${cfg.database.user} trust
      '';

      ensureDatabases = [
        cfg.database.name
        "matrix-sliding-sync"
      ];

      initialScript = pkgs.writeText "initial-setup.sql" ''
        CREATE USER ${cfg.database.user};
        GRANT ALL PRIVILEGES ON DATABASE ${cfg.database.name} TO ${cfg.database.user};
        CREATE USER matrix-sliding-sync;
        GRANT ALL PRIVILEGES ON DATABASE matrix-sliding-sync TO matrix-sliding-sync;
      '';
    };
  };
}
