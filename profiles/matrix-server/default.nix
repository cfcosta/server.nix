{
  config,
  inputs,
  dusk,
  ...
}:
{
  imports = [
    ../common.nix
    ./dendrite.nix
    inputs.agenix.nixosModules.default
  ];

  config = {
    age.secrets.dendrite-pem.file = dusk.secrets."dendrite.pem";

    dusk.dendrite = {
      enable = true;

      global = {
        serverName = "matrix.${dusk.domain}";
        privateKey = config.age.secrets.dendrite-pem.path;
      };
    };
  };
}
