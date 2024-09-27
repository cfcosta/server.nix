{
  pkgs,
  system,
  inputs,
}:
let
  inherit (builtins) readFile;
  inherit (inputs) deploy-rs nixos-anywhere;
in
{
  bootstrap = pkgs.writeShellApplication {
    name = "bootstrap";

    runtimeInputs = [
      nixos-anywhere.packages.${system}.default
    ];

    text = ''
      ${readFile ./lib.sh}
      ${readFile ./bootstrap.sh}
    '';
  };

  deploy = pkgs.writeShellApplication {
    name = "deploy";

    text = ''
      ${readFile ./lib.sh}

      exec ${deploy-rs.packages.${system}.default}/bin/deploy "$@"
    '';
  };
}
