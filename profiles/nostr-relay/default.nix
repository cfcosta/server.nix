{
  imports = [
    ../common.nix
    ./chronicle.nix
  ];

  config.services.chronicle = {
    enable = true;

    ownerPubkey = "xxx";
    name = "My Cool Relay";
    description = "";
    url = "";
    icon = "";
    contact = "";
  };
}
