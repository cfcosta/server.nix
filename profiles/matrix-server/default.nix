{
  config,
  inputs,
  dusk,
  ...
}:
{
  imports = [
    ../common.nix
    ./services/dendrite.nix
    inputs.agenix.nixosModules.default
  ];

  config = {
    age.secrets = {
      dendrite-pem.file = dusk.secrets."dendrite.pem";
      dendrite-shared-secret.file = dusk.secrets."dendrite.secret";
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
