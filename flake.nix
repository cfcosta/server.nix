{
  description = "A modular server configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-compat.url = "github:nix-community/flake-compat";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    chronicle = {
      url = "github:dtonon/chronicle";
      flake = false;
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        utils.follows = "flake-utils";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        gitignore.follows = "gitignore";
        flake-compat.follows = "flake-compat";
      };
    };
  };

  outputs =
    inputs@{
      self,

      deploy-rs,
      disko,
      flake-utils,
      nixpkgs,
      pre-commit-hooks,
      ...
    }:
    let
      inherit (builtins) mapAttrs;

      perSystem = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          inherit (pkgs) mkShell;

          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;

            hooks = {
              deadnix.enable = true;
              nixfmt-rfc-style.enable = true;

              shellcheck.enable = true;
              shfmt.enable = true;
            };
          };
        in
        {
          checks = {
            inherit pre-commit-check;
          };

          devShells.default = mkShell {
            inherit (pre-commit-check) shellHook;
            packages = [ deploy-rs.packages.${system}.default ];
          };
        }
      );
    in
    perSystem
    // {
      checks = mapAttrs (_: lib: lib.deployChecks self.deploy) deploy-rs.lib;

      deploy.nodes.nostr-relay = {
        hostname = "relay";
        fastConnection = true;

        profiles = {
          nostr-relay = {
            user = "root";
            sshUser = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nostr-relay;
          };
        };
      };

      nixosConfigurations = {
        bootstrap = nixpkgs.lib.nixosSystem {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
          };

          modules = [
            disko.nixosModules.disko
            ./bootstrap
            { config.dusk.target = "vultr"; }
          ];

          specialArgs = {
            inherit inputs;
          };
        };

        nostr-relay = nixpkgs.lib.nixosSystem {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
          };

          modules = [
            disko.nixosModules.disko
            ./bootstrap
            ./profiles/nostr-relay
            { config.dusk.target = "vultr"; }
          ];

          specialArgs = {
            inherit inputs;
          };
        };
      };
    };
}
