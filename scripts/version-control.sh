# ─────────────────────────────────────────
# Version Control
# ─────────────────────────────────────────

# -- git

setup_git() {
    section "Version Control — git"

    if command -v git >/dev/null 2>&1; then
        echo "  git is already installed."
    else
        echo "  Installing git..."
        case "$OS" in
            macos) brew install git ;;
            *)     sudo apt install git -y ;;
        esac
        echo "  git installed."
    fi
}

# -- git-lfs

setup_git_lfs() {
    section "Version Control — git-lfs"

    if command -v git-lfs >/dev/null 2>&1; then
        echo "  git-lfs is already installed."
    else
        echo "  Installing git-lfs..."
        case "$OS" in
            macos) brew install git-lfs ;;
            *)     sudo apt install git-lfs -y ;;
        esac
        echo "  git-lfs installed."
    fi

    if git config --global --get filter.lfs.process >/dev/null 2>&1; then
        echo "  git-lfs hooks are already registered globally."
    else
        echo "  Registering git-lfs hooks globally..."
        git lfs install
        echo "  git-lfs hooks registered."
    fi
}
