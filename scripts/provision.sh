#!/usr/bin/env bash

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# shellcheck source=/dev/null
. "${ROOT}/scripts/lib.sh"

NIX="nix --extra-experimental-features flakes --extra-experimental-features nix-command"

IP="${1}"
PROFILE="${2:-bootstrap}"

[ -z "${IP}" ] && _fatal "Usage: ${0} <user@hostname>"

setup_host

_info "Provisioning a new machine..."
_info "Target address: $(_blue "${IP}")"
_info "Installing profile: $(_blue "${PROFILE}")"

CMD="${NIX} run nix-darwin -- $CMD --flake ${ROOT}#${HOSTNAME}"
_info "Running command: $(_blue "${CMD}")"

${NIX} run github:nix-community/nixos-anywhere -- --flake "${ROOT}#${PROFILE}" "${IP}"
