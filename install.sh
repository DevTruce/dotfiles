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

# --- Shared setup (same on every OS) ----------------------------------------
setup_zsh_plugins() {
    echo "Setting up zsh plugin manager (zinit)..."
 
    ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
 
    if [ -d "$ZINIT_HOME" ]; then
        echo "zinit is already installed."
    else
        echo "Installing zinit..."
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    fi
 
    echo "Setting up completions directory..."
    mkdir -p "${HOME}/.zsh/completions"
 
    if command -v docker >/dev/null 2>&1; then
        echo "Generating docker zsh completion..."
        docker completion zsh > "${HOME}/.zsh/completions/_docker"
    else
        echo "docker not found, skipping docker completion (run setup again once Docker is available)."
    fi
}

setup_nvm() {
    echo "Setting up nvm..."

    NVM_DIR="${HOME}/.nvm"

    if [ -s "${NVM_DIR}/nvm.sh" ]; then
        echo "nvm is already installed."
    else
        echo "Installing nvm..."
        # PROFILE=/dev/null stops nvm's installer from editing .zshrc itself,
        # since the loader lines are already maintained by dotfiles.
        PROFILE=/dev/null bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh)"
    fi

    # nvm.sh and several nvm subcommands reference internal variables that
    # aren't always set, which trips `set -u`. Relax it for this block only.
   set +u
   \. "${NVM_DIR}/nvm.sh"


    if nvm ls --no-colors 2>/dev/null | grep -q 'lts/\*'; then
        echo "Node LTS is already installed via nvm."
    else
        echo "Installing latest Node LTS via nvm..."
        nvm install --lts
    fi

    nvm alias default 'lts/*' >/dev/null
    set -u
}


# --- Per-OS setup functions --------------------------------------------------
setup_macos() {
   echo "Running macOS setup..."

    echo "Checking if Homebrew already exists"
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew is already installed."
    else
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo "Updating Homebrew..."
    brew update

    echo "Upgrading installed packages..."
    brew upgrade

    echo "Checking if zsh already exists"
    if brew list zsh >/dev/null 2>&1; then
        echo "zsh is already installed via Homebrew."
    else
        echo "Installing zsh..."
        brew install zsh
    fi

    ZSH_PATH="$(brew --prefix zsh)/bin/zsh"

    if ! grep -qxF "$ZSH_PATH" /etc/shells; then
        echo "Adding ${ZSH_PATH} to /etc/shells..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi

    if [ "$SHELL" != "$ZSH_PATH" ]; then
        echo "Setting zsh as default shell..."
        chsh -s "$ZSH_PATH"
    else
        echo "zsh is already the default shell."
    fi

    setup_zsh_plugins
    setup_nvm
}

setup_linux() {
    echo "Running Linux setup..."

    echo "Updating package lists..."
    sudo apt update

    echo "Upgrading installed packages..."
    sudo apt upgrade -y

    echo "Checking if zsh already exists"
    if command -v zsh >/dev/null 2>&1; then
        echo "zsh is already installed."
    else
        echo "Installing zsh..."
        sudo apt install zsh -y
    fi

    if [ "$SHELL" != "$(command -v zsh)" ]; then
        echo "Setting zsh as default shell..."
        chsh -s "$(command -v zsh)"
    else
        echo "zsh is already the default shell."
    fi

    setup_zsh_plugins
    setup_nvm
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