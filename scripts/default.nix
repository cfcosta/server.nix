{
  dusk,
  pkgs,
  system,
  inputs,
}:
let
  inherit (builtins)
    attrNames
    readFile
    ;
  inherit (inputs) deploy-rs;
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

      runtimeInputs = with pkgs; [
        age
        awscli2
        jq
      ];

      text = ''
        ${readFile ./lib.sh}

        [ ! -d "secrets" ] && _fatal "You must be at the repository root folder."

        out=$(mktemp)

        # shellcheck disable=SC2016
        _info "Generating secret $(_red "${name}.age") with command: $(_blue '${generate}')"

        ${generate}

        _info "Generated new value for secret $(_red "${name}.age")"

        age --encrypt -o secrets/${name}.age ${args} "$out"

        _info "Done, updated secret $(_red "${name}.age")"
      '';
    };
in
rec {
  agenix = inputs.agenix.packages.${system}.default;

  bootstrap = pkgs.writeShellApplication {
    name = "server-bootstrap";

    runtimeInputs = [
      inputs.agenix.packages.${system}.default
      inputs.nixos-anywhere.packages.${system}.default
    ];

    text = ''
      ${readFile ./lib.sh}
      [ -f scripts/bootstrap.sh ] || _fatal "Bootstrap script is missing!"

      # shellcheck source=/dev/null
      . scripts/bootstrap.sh
    '';
  };

  update-keys = pkgs.writeShellApplication {
    name = "server-update-keys";

    text = ''
      ${readFile ./lib.sh}
      ip="$1"
      ssh-keyscan -t ed25519 "$ip" | grep -v "^#" | awk '{print $2,$3,"root@server"}' >> secrets/keys
      exec ${reencrypt-secrets}/bin/server-reencrypt-secrets
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
      secrets = map (s: ''
        _info "Generating secret: $(_red ${s})"

        ${generateSecret s}/bin/server-generate-secret
      '') (attrNames dusk.secrets);
      gen = concatStringsSep "\n\n" secrets;
    in
    pkgs.writeShellApplication {
      name = "server-re-generate-secrets";

      runtimeInputs = [
        inputs.agenix.packages.${system}.default
        pkgs.openssl
      ];

      text = ''
        ${readFile ./lib.sh}
        ${gen}
      '';
    };

  reencrypt-secrets = pkgs.writeShellApplication {
    name = "server-reencrypt-secrets";

    runtimeInputs = [
      inputs.agenix.packages.${system}.default
    ];

    text = ''
      ${readFile ./lib.sh}

      [ -f secrets/secrets.nix ] || _fatal "You must be at the project root for this to work."

      _info "Reencrypting all secrets"

      cd secrets

      agenix -r

      _info "Done"
    '';
  };
}
