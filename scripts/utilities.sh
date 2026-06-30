# ─────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────

# -- tree

setup_tree() {
    section "Utilities — tree"

    if command -v tree >/dev/null 2>&1; then
        skip "tree is already installed."
    else
        step "Installing tree"
        case "$OS" in
            macos) _brew install tree ;;
            *)     _apt install -y tree ;;
        esac
        ok "tree installed."
    fi
}

# -- fzf

setup_fzf() {
    section "Utilities — fzf"

    if command -v fzf >/dev/null 2>&1; then
        skip "fzf is already installed."
    else
        step "Installing fzf"
        case "$OS" in
            macos)
                _brew install fzf
                ;;
            *)
                # apt ships fzf 0.29–0.44 which predates `fzf --zsh`; pull latest from GitHub
                local _log _pid
                _log="$(mktemp)"
                (
                    case "$(uname -m)" in
                        aarch64) _arch="arm64" ;;
                        *)       _arch="amd64" ;;
                    esac
                    _version="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest \
                        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
                    curl -fsSLo /tmp/fzf.tar.gz \
                        "https://github.com/junegunn/fzf/releases/download/v${_version}/fzf-${_version}-linux_${_arch}.tar.gz"
                    mkdir -p "${HOME}/.local/bin"
                    tar -xzf /tmp/fzf.tar.gz -C "${HOME}/.local/bin/" fzf
                    rm -f /tmp/fzf.tar.gz
                ) > "$_log" 2>&1 &
                _pid=$!
                _spinner "$_pid"
                if wait "$_pid"; then rm -f "$_log"
                else warn "${_LAST_STEP} failed."; echo ""; cat "$_log"; rm -f "$_log"; return 1; fi
                ;;
        esac
        ok "fzf installed."
    fi
}

# -- zoxide

setup_zoxide() {
    section "Utilities — zoxide"

    if command -v zoxide >/dev/null 2>&1; then
        skip "zoxide is already installed."
    else
        step "Installing zoxide"
        case "$OS" in
            macos)
                _brew install zoxide
                ;;
            *)
                # zoxide not available in Ubuntu 22.04 apt repos; pull latest from GitHub
                local _log _pid
                _log="$(mktemp)"
                (
                    case "$(uname -m)" in
                        aarch64) _arch="aarch64-unknown-linux-musl" ;;
                        *)       _arch="x86_64-unknown-linux-musl" ;;
                    esac
                    _version="$(curl -fsSL https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest \
                        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
                    curl -fsSLo /tmp/zoxide.tar.gz \
                        "https://github.com/ajeetdsouza/zoxide/releases/download/v${_version}/zoxide-${_version}-${_arch}.tar.gz"
                    mkdir -p "${HOME}/.local/bin"
                    tar -xzf /tmp/zoxide.tar.gz -C "${HOME}/.local/bin/" zoxide
                    rm -f /tmp/zoxide.tar.gz
                ) > "$_log" 2>&1 &
                _pid=$!
                _spinner "$_pid"
                if wait "$_pid"; then rm -f "$_log"
                else warn "${_LAST_STEP} failed."; echo ""; cat "$_log"; rm -f "$_log"; return 1; fi
                ;;
        esac
        ok "zoxide installed."
    fi
}

# -- ripgrep

setup_ripgrep() {
    section "Utilities — ripgrep"

    if command -v rg >/dev/null 2>&1; then
        skip "ripgrep is already installed."
    else
        step "Installing ripgrep"
        case "$OS" in
            macos) _brew install ripgrep ;;
            *)     _apt install -y ripgrep ;;
        esac
        ok "ripgrep installed."
    fi
}

# -- bat

setup_bat() {
    section "Utilities — bat"

    # On Ubuntu/Debian, bat is installed as 'batcat' due to a naming conflict
    local _bat_cmd
    case "$OS" in
        macos) _bat_cmd="bat" ;;
        *)     _bat_cmd="batcat" ;;
    esac

    if command -v "$_bat_cmd" >/dev/null 2>&1; then
        skip "bat is already installed."
    else
        step "Installing bat"
        case "$OS" in
            macos) _brew install bat ;;
            *)     _apt install -y bat ;;
        esac
        ok "bat installed."
    fi
}

# -- lazygit

setup_lazygit() {
    section "Utilities — lazygit"

    if command -v lazygit >/dev/null 2>&1; then
        skip "lazygit is already installed."
    else
        step "Installing lazygit"
        case "$OS" in
            macos)
                _brew install lazygit
                ;;
            *)
                # lazygit not available in Ubuntu 22.04 apt repos; pull latest from GitHub
                local _log _pid
                _log="$(mktemp)"
                (
                    case "$(uname -m)" in
                        aarch64) _arch="arm64" ;;
                        *)       _arch="x86_64" ;;
                    esac
                    _version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
                        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
                    curl -fsSLo /tmp/lazygit.tar.gz \
                        "https://github.com/jesseduffield/lazygit/releases/download/v${_version}/lazygit_${_version}_Linux_${_arch}.tar.gz"
                    mkdir -p "${HOME}/.local/bin"
                    tar -xzf /tmp/lazygit.tar.gz -C "${HOME}/.local/bin/" lazygit
                    rm -f /tmp/lazygit.tar.gz
                ) > "$_log" 2>&1 &
                _pid=$!
                _spinner "$_pid"
                if wait "$_pid"; then rm -f "$_log"
                else warn "${_LAST_STEP} failed."; echo ""; cat "$_log"; rm -f "$_log"; return 1; fi
                ;;
        esac
        ok "lazygit installed."
    fi
}

# -- gh (GitHub CLI)

setup_gh() {
    section "Utilities — gh (GitHub CLI)"

    if command -v gh >/dev/null 2>&1; then
        skip "gh is already installed."
    else
        step "Installing gh (GitHub CLI)"
        case "$OS" in
            macos)
                _brew install gh
                ;;
            *)
                # apt ships an older gh; pull latest from GitHub releases
                local _log _pid
                _log="$(mktemp)"
                (
                    case "$(uname -m)" in
                        aarch64) _arch="arm64" ;;
                        *)       _arch="amd64" ;;
                    esac
                    _version="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest \
                        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
                    curl -fsSLo /tmp/gh.tar.gz \
                        "https://github.com/cli/cli/releases/download/v${_version}/gh_${_version}_linux_${_arch}.tar.gz"
                    mkdir -p "${HOME}/.local/bin"
                    tar -xzf /tmp/gh.tar.gz --strip-components=2 -C "${HOME}/.local/bin/" \
                        "gh_${_version}_linux_${_arch}/bin/gh"
                    rm -f /tmp/gh.tar.gz
                ) > "$_log" 2>&1 &
                _pid=$!
                _spinner "$_pid"
                if wait "$_pid"; then rm -f "$_log"
                else warn "${_LAST_STEP} failed."; echo ""; cat "$_log"; rm -f "$_log"; return 1; fi
                ;;
        esac
        ok "gh installed."
    fi
}
