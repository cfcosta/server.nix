{
  config,
  inputs,
  dusk,
  ...
}:
{
  imports = [
    ../common.nix
    ./server.nix
    inputs.agenix.nixosModules.default
  ];

  config = {
    dusk.dendrite = {
      enable = true;
      global.privateKey = config.age.secrets.dendrite-pem.path;
    };

    age.secrets.dendrite-pem.file = dusk.secrets."dendrite.pem";
  };
}
