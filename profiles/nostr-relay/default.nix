{
  imports = [
    ../common
    ../common/nginx.nix
    ./services/chronicle.nix
  ];

  config.dusk.chronicle = {
    enable = true;

    ownerPubkey = "xxx";
    name = "My Cool Relay";
    description = "";
    url = "";
    icon = "";
    contact = "";
  };
}
