# ─────────────────────────────────────────
# Version Control
# ─────────────────────────────────────────

# -- git

setup_git() {
    section "Version Control - git"

    if command -v git >/dev/null 2>&1; then
        skip "git is already installed."
    else
        step "Installing git"
        case "$OS" in
            macos) _brew install git ;;
            *)     _apt install -y git ;;
        esac
        ok "git installed."
    fi

    # -- Local identity (~/.gitconfig.local is not tracked in the repo)

    local git_local="${HOME}/.gitconfig.local"
    local existing_name existing_email existing_editor git_editor git_name git_email

    existing_name="$(git config --file "$git_local" user.name 2>/dev/null || true)"
    existing_email="$(git config --file "$git_local" user.email 2>/dev/null || true)"

    if [ -n "$existing_name" ] && [ -n "$existing_email" ]; then
        skip "Git identity already configured (${existing_name} <${existing_email}>)."
    else
        echo ""
        step "Setting up git identity in ~/.gitconfig.local"
        note "This file is not tracked in the repo."
        echo ""

        if [ -z "$existing_name" ]; then
            local _attempts=0
            git_name=""
            while [ -z "$git_name" ] && [ "$_attempts" -lt 3 ]; do
                printf "  Enter your git name:  "
                read -r git_name
                _attempts=$(( _attempts + 1 ))
            done
            if [ -z "$git_name" ]; then
                fail "Git name cannot be empty."
                return 1
            fi
            git config --file "$git_local" user.name "$git_name"
        fi

        if [ -z "$existing_email" ]; then
            local _attempts=0
            git_email=""
            while [ -z "$git_email" ] && [ "$_attempts" -lt 3 ]; do
                printf "  Enter your git email ${DIM}(tip: use your GitHub no-reply - github.com/settings/emails)${RESET}: "
                read -r git_email
                _attempts=$(( _attempts + 1 ))
            done
            if [ -z "$git_email" ]; then
                fail "Git email cannot be empty."
                return 1
            fi
            git config --file "$git_local" user.email "$git_email"
        fi

        ok "Git identity saved to ~/.gitconfig.local."
    fi

    existing_editor="$(git config --file "$git_local" core.editor 2>/dev/null || true)"

    if [ -z "$existing_editor" ]; then
        echo ""
        step "Select your git editor:"
        note "1) VS Code  (code --wait)"
        note "2) Neovim   (nvim)"
        note "3) Vim      (vim)"
        note "4) Nano     (nano)"
        note "5) Use system default (\$EDITOR)"
        printf "  Enter number: "
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
            ok "Git editor set to: ${git_editor}"
        else
            ok "Git editor left as system default (\$EDITOR)."
        fi
    else
        skip "Git editor already configured (${existing_editor})."
    fi
}

# -- git-lfs

setup_git_lfs() {
    section "Version Control - git-lfs"

    if command -v git-lfs >/dev/null 2>&1; then
        skip "git-lfs is already installed."
    else
        step "Installing git-lfs"
        case "$OS" in
            macos) _brew install git-lfs ;;
            *)     _apt install -y git-lfs ;;
        esac
        ok "git-lfs installed."
    fi

    # check for the actual pre-push hook rather than the filter config (which is pre-seeded
    # in the tracked .gitconfig and would always match, skipping hook registration forever)
    local _git_hooks_dir="${HOME}/.config/git/hooks"
    if git lfs env 2>/dev/null | grep -q "LocalGitStorageDir"; then
        skip "git-lfs hooks are already registered globally."
    else
        step "Registering git-lfs hooks globally"
        local _log
        _log="$(mktemp)"
        if git lfs install > "$_log" 2>&1; then
            rm -f "$_log"
        else
            fail "${_LAST_STEP} failed."
            echo ""
            cat "$_log"
            rm -f "$_log"
            return 1
        fi
        ok "git-lfs hooks registered."
    fi
}
