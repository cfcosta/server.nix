{
  imports = [ ./chronicle.nix ];

  config = {
    dusk.chronicle = {
      name = "My Cool Relay";
      description = "";
      url = "";
      icon = "";
      contact = "";
    };

    system.stateVersion = "24.11";
  };
}
