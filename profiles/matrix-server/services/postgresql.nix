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
        local ${dendrite.database.name} ${dendrite.database.user} trust
        local ${matrix-sliding-sync.database.name} ${matrix-sliding-sync.database.user} trust
      '';

      ensureDatabases = [
        dendrite.database.name
        matrix-sliding-sync.database.name
      ];

      initialScript = pkgs.writeText "initial-setup.sql" ''
        CREATE USER ${dendrite.database.user};
        GRANT ALL PRIVILEGES ON DATABASE ${dendrite.database.name} TO ${dendrite.database.user};

        CREATE USER ${matrix-sliding-sync.database.user};
        GRANT ALL PRIVILEGES ON DATABASE ${matrix-sliding-sync.database.name} TO ${matrix-sliding-sync.database.user};
      '';
    };
  };
}
