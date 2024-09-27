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

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
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

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        disko.follows = "disko";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        gitignore.follows = "gitignore";
        flake-compat.follows = "flake-compat";
      };
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,

      deploy-rs,
      flake-utils,
      nixpkgs,
      pre-commit-hooks,
      ...
    }:
    let
      inherit (builtins) attrValues mapAttrs;
      inherit (deploy-rs.lib.x86_64-linux) activate;

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
            packages = attrValues (import ./scripts { inherit pkgs system inputs; });
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

        profilesOrder = [ "nostr-relay" ];

        profiles = {
          nostr-relay = {
            user = "root";
            sshUser = "root";
            path = activate.nixos self.nixosConfigurations.nostr-relay;
          };
        };
      };

      nixosConfigurations = {
        bootstrap = nixpkgs.lib.nixosSystem {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
          };

          modules = [ ./profiles/bootstrap ];

          specialArgs = {
            inherit inputs;
            dusk = import ./config.nix;
          };
        };

        nostr-relay = nixpkgs.lib.nixosSystem {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
          };

          modules = [ ./profiles/nostr-relay ];

          specialArgs = {
            inherit inputs;
            dusk = import ./config.nix;
          };
        };

        matrix-server = nixpkgs.lib.nixosSystem {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
          };

          modules = [ ./profiles/matrix-server ];

          specialArgs = {
            inherit inputs;
            dusk = import ./config.nix;
          };
        };
      };
    };
}
