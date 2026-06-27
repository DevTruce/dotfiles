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

    # -- Local identity (~/.gitconfig.local is not tracked in the repo)

    local git_local="${HOME}/.gitconfig.local"
    local existing_name existing_email

    existing_name="$(git config --file "$git_local" user.name 2>/dev/null || true)"
    existing_email="$(git config --file "$git_local" user.email 2>/dev/null || true)"

    if [ -n "$existing_name" ] && [ -n "$existing_email" ]; then
        echo "  Git identity already configured (${existing_name} <${existing_email}>)."
    else
        echo ""
        echo "  Git identity is stored in ~/.gitconfig.local (not tracked in the repo)."
        echo ""

        if [ -z "$existing_name" ]; then
            printf "  Enter your git name:  "
            read -r git_name
            git config --file "$git_local" user.name "$git_name"
        fi

        if [ -z "$existing_email" ]; then
            printf "  Enter your git email (tip: use your GitHub no-reply address — github.com/settings/emails): "
            read -r git_email
            git config --file "$git_local" user.email "$git_email"
        fi

        echo "  Git identity saved to ~/.gitconfig.local."
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
