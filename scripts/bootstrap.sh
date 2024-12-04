#!/usr/bin/env bash

HOST="${1}"
FLAKE_TARGET="${2:-.#bootstrap}"

[ -z "${HOST}" ] && _fatal "Usage: ${0} <user@hostname>"

setup_host

_info "Provisioning a new machine..."
_info "Target address: $(_blue "${HOST}")"
_info "Installing profile: $(_blue "${FLAKE_TARGET}")"

CMD="nixos-anywhere --flake ${FLAKE_TARGET} ${HOST}"
_info "Running command: $(_blue "${CMD}")"
exec ${CMD}
