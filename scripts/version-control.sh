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
    local existing_name existing_email existing_editor git_editor git_name git_email

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

    existing_editor="$(git config --file "$git_local" core.editor 2>/dev/null || true)"

    if [ -z "$existing_editor" ]; then
        echo ""
        echo "  Select your git editor:"
        echo "    1) VS Code  (code --wait)"
        echo "    2) Neovim   (nvim)"
        echo "    3) Vim      (vim)"
        echo "    4) Nano     (nano)"
        echo "    5) Use system default (\$EDITOR)"
        printf "  Enter number [1]: "
        read -r editor_choice
        case "${editor_choice:-1}" in
            2) git_editor="nvim" ;;
            3) git_editor="vim" ;;
            4) git_editor="nano" ;;
            5) git_editor="" ;;
            *) git_editor="code --wait" ;;
        esac
        if [ -n "$git_editor" ]; then
            git config --file "$git_local" core.editor "$git_editor"
            echo "  Git editor set to: ${git_editor}"
        else
            echo "  Git editor left as system default (\$EDITOR)."
        fi
    else
        echo "  Git editor already configured (${existing_editor})."
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
        echo ""
        echo "  git-lfs hooks registered."
    fi
}
