# ─────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────

# -- tree

setup_tree() {
    section "Utilities - tree"

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
    section "Utilities - fzf"

    if command -v fzf >/dev/null 2>&1; then
        skip "fzf is already installed."
    else
        step "Installing fzf"
        case "$OS" in
            macos)
                _brew install fzf
                ;;
            *)
                # apt ships fzf 0.29-0.44 which predates `fzf --zsh`; pull latest from GitHub
                _install_fzf_linux() {
                    local _arch _version _asset _dl
                    _arch="$(_uname_arch arm64 amd64)"
                    _version="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest \
                        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
                    if [ -z "$_version" ]; then
                        echo "ERROR: could not determine fzf version (GitHub API rate limit?)" >&2
                        return 1
                    fi
                    _asset="fzf-${_version}-linux_${_arch}.tar.gz"
                    _dl="$(mktemp)"
                    curl -fsSLo "$_dl" \
                        "https://github.com/junegunn/fzf/releases/download/v${_version}/${_asset}"
                    _verify_sha256 "$_dl" \
                        "https://github.com/junegunn/fzf/releases/download/v${_version}/fzf_${_version}_checksums.txt" \
                        "$_asset" || { rm -f "$_dl"; return 1; }
                    mkdir -p "${HOME}/.local/bin"
                    tar -xzf "$_dl" -C "${HOME}/.local/bin/" fzf
                    rm -f "$_dl"
                }
                _run_with_spinner _install_fzf_linux || return 1
                ;;
        esac
        ok "fzf installed."
    fi
}

# -- zoxide

setup_zoxide() {
    section "Utilities - zoxide"

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
                _install_zoxide_linux() {
                    local _arch _version _dl
                    _arch="$(_uname_arch aarch64-unknown-linux-musl x86_64-unknown-linux-musl)"
                    _version="$(curl -fsSL https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest \
                        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
                    if [ -z "$_version" ]; then
                        echo "ERROR: could not determine zoxide version (GitHub API rate limit?)" >&2
                        return 1
                    fi
                    _dl="$(mktemp)"
                    curl -fsSLo "$_dl" \
                        "https://github.com/ajeetdsouza/zoxide/releases/download/v${_version}/zoxide-${_version}-${_arch}.tar.gz"
                    # zoxide does not publish a checksums file in its GitHub releases (unlike
                    # fzf/lazygit/gh, verified via the API), so sha256 verification isn't
                    # possible here; at minimum confirm the download is a valid archive
                    # containing the expected binary before extracting it onto $PATH
                    if ! tar -tzf "$_dl" zoxide >/dev/null 2>&1; then
                        echo "ERROR: downloaded zoxide archive is invalid or missing the zoxide binary" >&2
                        rm -f "$_dl"
                        return 1
                    fi
                    mkdir -p "${HOME}/.local/bin"
                    tar -xzf "$_dl" -C "${HOME}/.local/bin/" zoxide
                    rm -f "$_dl"
                }
                _run_with_spinner _install_zoxide_linux || return 1
                ;;
        esac
        ok "zoxide installed."
    fi
}

# -- ripgrep

setup_ripgrep() {
    section "Utilities - ripgrep"

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
    section "Utilities - bat"

    local _bat_cmd
    _bat_cmd="$(_bat_binary_name)"

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
    section "Utilities - lazygit"

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
                _install_lazygit_linux() {
                    local _arch _version _asset _dl
                    _arch="$(_uname_arch arm64 x86_64)"
                    _version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
                        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
                    if [ -z "$_version" ]; then
                        echo "ERROR: could not determine lazygit version (GitHub API rate limit?)" >&2
                        return 1
                    fi
                    _asset="lazygit_${_version}_linux_${_arch}.tar.gz"
                    _dl="$(mktemp)"
                    curl -fsSLo "$_dl" \
                        "https://github.com/jesseduffield/lazygit/releases/download/v${_version}/${_asset}"
                    _verify_sha256 "$_dl" \
                        "https://github.com/jesseduffield/lazygit/releases/download/v${_version}/checksums.txt" \
                        "$_asset" || { rm -f "$_dl"; return 1; }
                    mkdir -p "${HOME}/.local/bin"
                    tar -xzf "$_dl" -C "${HOME}/.local/bin/" lazygit
                    rm -f "$_dl"
                }
                _run_with_spinner _install_lazygit_linux || return 1
                ;;
        esac
        ok "lazygit installed."
    fi
}

# -- gh (GitHub CLI)

setup_gh() {
    section "Utilities - gh (GitHub CLI)"

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
                _install_gh_linux() {
                    local _arch _version _asset _dl
                    _arch="$(_uname_arch arm64 amd64)"
                    _version="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest \
                        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
                    if [ -z "$_version" ]; then
                        echo "ERROR: could not determine gh version (GitHub API rate limit?)" >&2
                        return 1
                    fi
                    _asset="gh_${_version}_linux_${_arch}.tar.gz"
                    _dl="$(mktemp)"
                    curl -fsSLo "$_dl" \
                        "https://github.com/cli/cli/releases/download/v${_version}/${_asset}"
                    _verify_sha256 "$_dl" \
                        "https://github.com/cli/cli/releases/download/v${_version}/gh_${_version}_checksums.txt" \
                        "$_asset" || { rm -f "$_dl"; return 1; }
                    mkdir -p "${HOME}/.local/bin"
                    # unlike fzf/zoxide/lazygit's flat binaries, gh's tarball nests the
                    # binary under <pkg>/bin/gh - strip both directory levels on extract
                    tar -xzf "$_dl" --strip-components=2 -C "${HOME}/.local/bin/" \
                        "gh_${_version}_linux_${_arch}/bin/gh"
                    rm -f "$_dl"
                }
                _run_with_spinner _install_gh_linux || return 1
                ;;
        esac
        ok "gh installed."
    fi
}
