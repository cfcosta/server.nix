{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.dusk-matrix-server;
in
{
  imports = [
    inputs.agenix.nixosModules.default
    ../common.nix
  ];

  options.services.dusk-matrix-server = {
    enable = mkEnableOption "Dendrite Matrix Server";

    global = {
      serverName = mkOption {
        type = types.str;
        default = "dusk.com";
      };

      privateKey = mkOption {
        type = types.str;
      };
    };

    jetstream = {
      storagePath = mkOption {
        type = types.str;
      };
    };

    metrics = {
      enable = mkEnableOption "Enable Prometheus Metric Collection";
    };

    dnsCache = {
      enable = mkEnableOption "Enable Optional DNS cache. The DNS cache may reduce the load on DNS servers if there is no local caching resolver available for use.";
    };

    clientApi = {
      registrationEnabled = mkEnableOption "Allows new users from being able to register on this homeserver.";
      guestsEnabled = mkEnableOption "Allows new guest accounts from being created.";
    };
  };

  config = mkIf cfg.enable {
    services = {
      dendrite = {
        enable = true;

        settings = {
          global = {
            server_name = cfg.global.serverName;
            private_key = cfg.global.privateKey;
          };

          client_api.registration_shared_secret = "$REGISTRATION_SHARED_SECRET";
        };
      };

      postgresql = {
        enable = true;
        enableJIT = true;
      };
    };
  };
}
