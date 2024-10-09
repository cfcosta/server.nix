{
  dusk,
  pkgs,
  system,
  inputs,
}:
let
  inherit (builtins) attrNames readFile;
  inherit (inputs) deploy-rs nixos-anywhere;
  inherit (pkgs.lib) concatStringsSep;

  generateSecret =
    name:
    let
      secret = dusk.secrets.${name};
      keys = (import ../secrets/secrets.nix)."${name}.age".publicKeys;
      args = concatStringsSep " " (map (k: ''-r "${k}"'') keys);
      generate = secret.generate pkgs;
    in
    pkgs.writeShellApplication {
      name = "server-generate-secret";

      runtimeInputs = with pkgs; [ age ];

      text = ''
        ${readFile ./lib.sh}

        [ ! -d "secrets" ] && _fatal "You must be at the repository root folder."
        grep "${name}.age" secrets/secrets.nix &>/dev/null || _fatal "The secret does not exist on the secrets file."

        out=$(mktemp)
        cmd="$(echo -n ${generate})"

        _info "Generating secret $(_red "${name}.age") with command: $(_blue "$cmd")"

        ${generate}

        _info "Generated new value for secret $(_red "${name}.age")"

        age --encrypt -o secrets/${name}.age ${args} "$out"

        _info "Done, updated secret $(_red "${name}.age")"
      '';
    };
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

  re-generate-secrets =
    let
      secrets = map (s: "${generateSecret s}/bin/server-generate-secret") (attrNames dusk.secrets);
      gen = concatStringsSep "\n\n" secrets;
    in
    pkgs.writeShellApplication {
      name = "server-re-generate-secrets";

      text = ''
        ${readFile ./lib.sh}
        ${gen}
      '';
    };

  reencrypt-secrets = pkgs.writeShellApplication {
    name = "server-reencrypt-secrets";

    text = ''
      ${readFile ./lib.sh}
      [ -f secrets/secrets.nix ] || _fatal "You must be at the project root for this to work."
    '';
  };
}
