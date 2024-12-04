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
      dusk = import ./config.nix;

      nixos =
        {
          system ? "x86_64-linux",
          profiles ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          pkgs = import nixpkgs {
            inherit system;
          };

          modules = map (p: ./profiles/${p}) profiles;

          specialArgs = {
            inherit dusk inputs;
          };
        };
    in
    {
      checks = mapAttrs (_: lib: lib.deployChecks self.deploy) deploy-rs.lib;

      deploy.nodes.server = {
        hostname = "server";
        fastConnection = true;

        profiles.server = {
          user = "root";
          sshUser = "root";

          path = activate.nixos (nixos {
            profiles = [
              "nostr-relay"
            ];
          });
        };
      };

      nixosConfigurations.bootstrap = nixos { profiles = [ "bootstrap" ]; };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        inherit (pkgs) mkShell;

        checks.pre-commit-check = pre-commit-hooks.lib.${system}.run {
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
        inherit checks;

        devShells.default = mkShell {
          inherit (checks.pre-commit-check) shellHook;

          packages = attrValues (
            import ./scripts {
              inherit
                dusk
                inputs
                pkgs
                system
                ;
            }
          );
        };
      }
    );
}
