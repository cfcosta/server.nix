{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkForce
    mkIf
    mkOption
    types
    ;

  cfg = config.dusk.matrix-sliding-sync;
  generateConnectionString =
    {
      user,
      password,
      host,
      port,
      name,
      sslMode,
      ...
    }:
    "postgresql://${user}${
      if password != null then ":${password}" else ""
    }@${host}:${toString port}/${name}?sslmode=${sslMode}";
in
{
  options.dusk.matrix-sliding-sync = {
    enable = mkEnableOption "Matrix Sliding Sync";

    server = mkOption {
      type = types.str;
      default = config.dusk.dendrite.global.serverName;
      description = "The server name for the Matrix server.";
    };

    environmentFile = mkOption {
      type = types.path;
      description = "Path to the environment file containing secrets.";
    };

    rootDir = mkOption {
      type = types.str;
      default = "/var/lib/matrix-sliding-sync";
      description = "The root directory for the sync proxy to run inside.";
    };

    user = mkOption {
      type = types.str;
      default = "matrix-sliding-sync";
      description = "The user under which the Matrix Sliding Sync service runs.";
    };

    group = mkOption {
      type = types.str;
      default = "matrix-sliding-sync";
      description = "The group under which the Matrix Sliding Sync service runs.";
    };

    database = {
      user = mkOption {
        type = types.str;
        default = config.dusk.matrix-sliding-sync.user;
        description = "The database user.";
      };

      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The database password.";
      };

      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "The database host.";
      };

      port = mkOption {
        type = types.int;
        default = 5432;
        description = "The database port.";
      };

      name = mkOption {
        type = types.str;
        default = "matrix-sliding-sync";
        description = "The database name.";
      };

      sslMode = mkOption {
        type = types.enum [
          "disable"
          "require"
          "verify-ca"
          "verify-full"
        ];
        default = "disable";
        description = "The SSL mode for the database connection.";
      };
      maxOpenConns = mkOption {
        type = types.int;
        default = 90;
        description = "The maximum number of open connections to the database.";
      };
      maxIdleConns = mkOption {
        type = types.int;
        default = 5;
        description = "The maximum number of connections in the idle connection pool.";
      };
      connMaxLifetime = mkOption {
        type = types.int;
        default = -1;
        description = "The maximum amount of time a connection may be reused.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.matrix-sliding-sync = {
      inherit (cfg) environmentFile;

      enable = true;
      createDatabase = true;

      settings = {
        SYNCV3_SERVER = "https://${cfg.server}";
        SYNCV3_DB = generateConnectionString cfg.database;
      };
    };

    systemd = {
      services.matrix-sliding-sync.serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = mkForce cfg.rootDir;
        EnvironmentFile = mkForce cfg.environmentFile;
      };

      tmpfiles.rules = [
        "d ${cfg.rootDir} 0750 ${cfg.user} ${cfg.group} -"
      ];
    };

    users = {
      groups.${cfg.group} = { };

      users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.rootDir;
        createHome = false;
      };
    };
  };
}
