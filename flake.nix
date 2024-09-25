{
  description = "A modular server configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-compat.url = "github:nix-community/flake-compat";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
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

      disko,
      flake-utils,
      nixpkgs,
      pre-commit-hooks,
      ...
    }:
    let
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

          buildRoot = name: self.outputs.nixosConfigurations."${name}".config.system.build;
        in
        {
          checks = {
            inherit pre-commit-check;
          };

          devShells.default = mkShell {
            inherit (pre-commit-check) shellHook;
          };
          packages = {
            default = (buildRoot "default").toplevel;
            vm = (buildRoot "qemu").vm;
          };
        }
      );
    in
    perSystem
    // {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        pkgs = import nixpkgs { system = "x86_64-linux"; };

        modules = [
          disko.nixosModules.disko
          ./modules
          { config.dusk.target = "digitalocean"; }
        ];

        specialArgs = {
          inherit inputs;
        };
      };

      nixosConfigurations.qemu = nixpkgs.lib.nixosSystem {
        pkgs = import nixpkgs { system = "x86_64-linux"; };

        modules = [
          disko.nixosModules.disko
          ./modules
          { config.dusk.target = "qemu"; }
        ];

        specialArgs = {
          inherit inputs;
        };
      };
    };
}
