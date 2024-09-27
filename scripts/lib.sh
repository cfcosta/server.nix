#!/usr/bin/env bash

export COLORS_NONE='\033[0m' # No Color
export COLORS_BLACK='\033[0;30m'
export COLORS_RED='\033[0;31m'
export COLORS_GREEN='\033[0;32m'
export COLORS_YELLOW='\033[0;33m'
export COLORS_BLUE='\033[0;34m'
export COLORS_PURPLE='\033[0;35m'
export COLORS_CYAN='\033[0;36m'
export COLORS_WHITE='\033[0;37m'

_black() {
	echo -e "${COLORS_BLACK}$1${COLORS_NONE}"
}

_red() {
	echo -e "${COLORS_RED}$1${COLORS_NONE}"
}

_green() {
	echo -e "${COLORS_GREEN}$1${COLORS_NONE}"
}

_yellow() {
	echo -e "${COLORS_YELLOW}$1${COLORS_NONE}"
}

_blue() {
	echo -e "${COLORS_BLUE}$1${COLORS_NONE}"
}

_purple() {
	echo -e "${COLORS_PURPLE}$1${COLORS_NONE}"
}

_cyan() {
	echo -e "${COLORS_CYAN}$1${COLORS_NONE}"
}

_white() {
	echo -e "${COLORS_WHITE}$1${COLORS_NONE}"
}

_info() {
	echo -e ":: $(_green "[INFO]") $1"
}

_warn() {
	echo -e ":: $(_yellow "[WARN]") $1" >&2
}

_error() {
	echo -e ":: $(_red "[ERROR]") $1" >&2
}

_fatal() {
	echo -e ":: $(_red "[FATAL]") $1" >&2
	exit 1
}

setup_host() {
	check_nix

	case "$(uname -s)" in
	"Darwin")
		setup_host_darwin
		;;
	"Linux")
		setup_host_linux
		;;
	*)
		_fatal "Invalid base system."
		;;
	esac
}

setup_host_linux() {
	_info "Done setting up Linux system."

	return 0
}

setup_host_darwin() {
	setup_host_darwin_xcode_cli_tools
	setup_host_darwin_xcode_license

	NIX_ROOT="/run/current-system/sw"

	export PATH="${NIX_ROOT}/bin:$PATH"

	check_nix

	# Make sure we are connected to the Nix Daemon
	# shellcheck source=/dev/null
	if [ -e "${NIX_ROOT}/etc/profile.d/nix-daemon.sh" ]; then
		_info "Found Nix Daemon script: $(_blue "${NIX_ROOT}/etc/profile.d/nix-daemon.sh")"

		. "${NIX_ROOT}/etc/profile.d/nix-daemon.sh"
	fi
}

setup_host_darwin_xcode_cli_tools() {
	if xcode-select -p &>/dev/null; then
		_info "Found command-line tools: $(_blue "$(xcode-select -p)")"
		return 0
	fi

	_warn "Xcode Command Line Tools are not installed, installing..."

	xcode-select --install

	_info "Please follow the prompts to install Xcode Command Line Tools."
	_info "After installation is complete, please run this script again."

	if ! xcode-select -p &>/dev/null; then
		_fatal "Even after install, could not find installed command line tools, please try again"
	fi
}

setup_darwin_xcode_license() {
	XCODE_VERSION="$(xcodebuild -version | grep '^Xcode\s' | sed -E 's/^Xcode[[:space:]]+([0-9\.]+)/\1/')"
	ACCEPTED_LICENSE_VERSION="$(defaults read /Library/Preferences/com.apple.dt.Xcode 2>/dev/null | grep IDEXcodeVersionForAgreedToGMLicense | cut -d '"' -f 2)"

	_info "Found XCode version: $(_blue "${XCODE_VERSION}")"
	_info "Accepted XCode License Version: $(_blue "${ACCEPTED_LICENSE_VERSION}")"

	if [ "$XCODE_VERSION" != "$ACCEPTED_LICENSE_VERSION" ]; then
		_warn "You need to accept the current version XCode License, please input your password for sudo."
		_info "Running command: sudo xcodebuild -license accept"

		sudo xcodebuild -license accept && return 0

		_fatal "Could not accept XCode License"
	fi

	_info "Done setting up Darwin system."

	return 0
}

check_nix() {
	if which nix &>/dev/null; then
		_info "Found Nix: $(_blue "$(which nix)")"
	else
		_fatal "Nix not found!"
	fi

	return 0
}
