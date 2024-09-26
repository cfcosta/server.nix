{ inputs, pkgs }:
let
  inherit (inputs) disko nixpkgs;
in
nixpkgs.lib.nixosSystem {
  inherit pkgs;

  modules = [
    disko.nixosModules.disko
    ../../modules
    ./service.nix
    {
      config = {
        dusk = {
          target = "digitalocean";

          nostr-relay = {
            name = "My Cool Relay";
            description = "";
            url = "";
            icon = "";
            contact = "";
          };
        };
      };
    }
  ];

  specialArgs = {
    inherit inputs;
  };
}
