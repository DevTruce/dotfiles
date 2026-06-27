# ─────────────────────────────────────────
# Package Managers
# ─────────────────────────────────────────

# -- Homebrew (macOS)

setup_homebrew() {
    section "Package Manager — Homebrew"

    if command -v brew >/dev/null 2>&1; then
        echo "  Homebrew is already installed."
    else
        echo "  Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo "  Homebrew installed."
    fi

    echo "  Fetching latest Homebrew updates..."
    brew update

    echo "  Upgrading outdated packages..."
    # || true prevents a single failed formula from aborting the installer
    brew upgrade || true
}

# -- apt (Linux)

setup_apt() {
    section "Package Manager — apt"

    echo "  Refreshing package lists..."
    sudo apt update

    echo "  Upgrading outdated packages..."
    sudo apt upgrade -y
}
