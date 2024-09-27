{
  imports = [ ./chronicle.nix ];

  config = {
    dusk.chronicle = {
      enable = true;

      ownerPubkey = "xxx";
      name = "My Cool Relay";
      description = "";
      url = "";
      icon = "";
      contact = "";
    };

    system.stateVersion = "24.11";
  };
}
