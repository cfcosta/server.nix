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
  agenix = inputs.agenix.packages.${system}.default;

  bootstrap = pkgs.writeShellApplication {
    name = "server-bootstrap";

    runtimeInputs = [
      nixos-anywhere.packages.${system}.default
    ];

    text = ''
      ${readFile ./lib.sh}
      ${readFile ./bootstrap.sh}
    '';
  };

  deploy = pkgs.writeShellApplication {
    name = "server-deploy";

    text = ''
      ${readFile ./lib.sh}

      exec ${deploy-rs.packages.${system}.default}/bin/deploy "$@"
    '';
  };
}
