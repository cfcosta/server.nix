{ config, dusk, ... }:
{
  imports = [
    ../../common
    ./services
  ];

  config = {
    age.secrets = {
      dendrite-pem = {
        file = dusk.secrets."dendrite.pem".path;
        mode = "0600";
        owner = config.dusk.dendrite.user;
        path = "/etc/dendrite/matrix_key.pem";
      };

      dendrite-shared-secret = {
        file = dusk.secrets."dendrite.secret".path;
        mode = "0600";
        owner = config.dusk.dendrite.user;
      };

      dendrite-sliding-sync-secret = {
        file = dusk.secrets."dendrite-sliding-sync.secret".path;
        mode = "0600";
        owner = config.dusk.matrix-sliding-sync.user;
        path = "/etc/matrix-sliding-sync/env.sh";
      };
    };

    dusk = {
      dendrite = {
        enable = true;

        global = {
          serverName = "matrix.${dusk.domain}";
          privateKey = config.age.secrets.dendrite-pem.path;

          presence.enableInbound = true;
        };

        clientAPI.registrationSharedSecretPath = config.age.secrets.dendrite-shared-secret.path;
        syncAPI.search.enable = true;
      };

      matrix-sliding-sync = {
        enable = true;

        server = dusk.domain;
        environmentFile = config.age.secrets.dendrite-sliding-sync-secret.path;
      };

      tor.enable = false;
    };
  };
}
