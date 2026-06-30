# ─────────────────────────────────────────
# Shell
# ─────────────────────────────────────────

# -- zsh

setup_zsh() {
    section "Shell - zsh"

    local ZSH_PATH

    case "$OS" in
        macos)
            if brew list zsh >/dev/null 2>&1; then
                skip "zsh is already installed via Homebrew."
            else
                step "Installing zsh via Homebrew"
                _brew install zsh
                ok "zsh installed."
            fi

            if ! command -v brew >/dev/null 2>&1; then
                fail "brew not found - cannot determine zsh path."
                return 1
            fi
            # use brew's path explicitly rather than `command -v zsh`, which could
            # resolve to /bin/zsh (the older system zsh) if it comes first in PATH
            ZSH_PATH="$(brew --prefix zsh)/bin/zsh"

            # chsh only accepts shells listed in /etc/shells - Homebrew's zsh isn't
            # there by default, so it has to be registered before setting it below
            if ! grep -qxF "$ZSH_PATH" /etc/shells; then
                step "Registering ${ZSH_PATH} in /etc/shells"
                echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
                ok "zsh registered in /etc/shells."
            fi
            ;;
        *)
            if command -v zsh >/dev/null 2>&1; then
                skip "zsh is already installed."
            else
                step "Installing zsh"
                _apt install -y zsh
                ok "zsh installed."
            fi

            ZSH_PATH="$(command -v zsh)"
            ;;
    esac

    # compare against the OS-level configured shell (not $SHELL which reflects the login session)
    local _configured_shell
    case "$OS" in
        macos) _configured_shell="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')" ;;
        *)     _configured_shell="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)" ;;
    esac

    if [ "$_configured_shell" = "$ZSH_PATH" ]; then
        skip "zsh is already the default shell."
    else
        step "Setting zsh as the default shell"
        sudo chsh -s "$ZSH_PATH" "$USER"
        ok "Default shell updated"
    fi
}
