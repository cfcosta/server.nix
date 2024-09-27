{
  imports = [
    ./server.nix
  ];

  config.services.dusk-matrix-server = {
    enable = true;
  };
}
