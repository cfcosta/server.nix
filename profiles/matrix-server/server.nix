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
in
{
  imports = [
    inputs.agenix.nixosModules.default
    ../common.nix
  ];

  options.services.dusk-matrix-server = {
    enable = mkEnableOption "Dendrite Matrix Server";

    domain = mkOption {
      type = types.str;
      default = "dusk.com";
    };
  };

  config = mkIf config.services.dusk-matrix-server.enable {
    services = {
      postgresql = {
        enable = true;
        enableJIT = true;
      };

      dendrite = {
        enable = true;

        environmentFile = "/run/todo-env-var";

        settings = {
          global = {
            server_name = config.services.dusk-matrix-server.domain;
            private_key = "/run/todo-private-key";
          };

          client_api.registration_shared_secret = "$REGISTRATION_SHARED_SECRET";
        };
      };
    };
  };
}
