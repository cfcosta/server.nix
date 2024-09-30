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
      ];

      initialScript = pkgs.writeText "initial-setup.sql" ''
        CREATE USER ${cfg.database.user};
        GRANT ALL PRIVILEGES ON DATABASE ${cfg.database.name} TO ${cfg.database.user};
      '';
    };
  };
}
