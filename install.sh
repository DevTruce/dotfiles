#!/usr/bin/env bash
set -euo pipefail

# --- OS detection -----------------------------------------------------------
detect_os() {
    case "$(uname -s)" in
        Linux*)
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                echo "${ID:-linux}"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

OS="$(detect_os)"
echo "Detected OS: ${OS}"

# --- Per-OS setup functions --------------------------------------------------
setup_macos() {
    echo "Running macOS setup..."
    # mac-specific steps go here (brew, mac paths, etc.)
}

setup_linux() {
    echo "Running Linux setup..."
    # linux-specific steps go here (apt/pacman/dnf, linux paths, etc.)
}

# --- Dispatch ----------------------------------------------------------------
if [ "$OS" = "macos" ]; then
    setup_macos
elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ] || [ "$OS" = "arch" ] || [ "$OS" = "fedora" ] || [ "$OS" = "linux" ]; then
    setup_linux
else
    echo "Unsupported OS: ${OS}" >&2
    exit 1
fi