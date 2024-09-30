{
  config,
  inputs,
  dusk,
  ...
}:
{
  imports = [
    ../common
    ../common/nginx.nix
    ./services/nginx.nix
    ./services/postgresql.nix
    ./services/dendrite.nix
    inputs.agenix.nixosModules.default
  ];

  config = {
    age.secrets = {
      dendrite-pem = {
        file = dusk.secrets."dendrite.pem";
        mode = "0600";
        owner = config.dusk.dendrite.user;
      };

      dendrite-shared-secret = {
        file = dusk.secrets."dendrite.secret";
        mode = "0600";
        owner = config.dusk.dendrite.user;
      };
    };

    dusk.dendrite = {
      enable = true;

      clientAPI.registrationSharedSecretPath = config.age.secrets.dendrite-shared-secret.path;

      global = {
        serverName = "matrix.${dusk.domain}";
        privateKey = config.age.secrets.dendrite-pem.path;
      };
    };
  };
}
