#!/usr/bin/env bash
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="${HOME}/.local/bin:${PATH}"

. "${DOTFILES_DIR}/scripts/helpers.sh"
OS="$(detect_os)"

# ─────────────────────────────────────────
# Check Counters
# ─────────────────────────────────────────

_PASS=0
_FAIL=0
_WARN=0

_pass()    { ok   "$1"; _PASS=$((_PASS + 1)); }
_fail()    { fail "$1"; _FAIL=$((_FAIL + 1)); }
_warn()    { warn "$1"; _WARN=$((_WARN + 1)); }
_pending() { skip "$1"; }  # dim ✓ — will materialize on first shell launch, not a problem

# ─────────────────────────────────────────
# Header
# ─────────────────────────────────────────

echo ""
printf "  ${BOLD_CYAN}┌──────────────────────────────────────────────────────┐${RESET}\n"
printf "  ${BOLD_CYAN}│${RESET}  ${BOLD_WHITE}%-52s${RESET}${BOLD_CYAN}│${RESET}\n" "System Check"
printf "  ${BOLD_CYAN}│${RESET}  ${DIM}%-52s${RESET}${BOLD_CYAN}│${RESET}\n" "OS: ${OS}"
printf "  ${BOLD_CYAN}└──────────────────────────────────────────────────────┘${RESET}\n"
echo ""
note "Tip: open a new terminal after install.sh before running this check for full accuracy"
echo ""

# doctor.sh is diagnostic-only (never blocks), so an unrecognized OS just gets a warning
# here rather than a hard stop like install.sh's - every case "$OS" in macos) ...; *) ...
# check below still runs against it, falling back to apt/Debian-based expectations.
if ! _is_supported_os; then
    _warn "Unrecognized OS: ${OS} - checks below assume apt-based (Ubuntu/Debian) behavior for anything that isn't macOS."
fi

# ─────────────────────────────────────────
# Shell
# ─────────────────────────────────────────

section "Shell"

if command -v zsh >/dev/null 2>&1; then
    _zsh_ver="$(zsh --version 2>/dev/null | awk '{print $2}')"
    _pass "zsh  ${_zsh_ver}"
else
    _fail "zsh  not found"
fi

# _configured_login_shell() (scripts/helpers.sh) reads the OS-level login shell
# directly (dscl/getent), not $SHELL, since $SHELL only reflects the shell the
# current session happens to be running, not what's configured
_configured_shell="$(_configured_login_shell)"
_zsh_path="$(command -v zsh 2>/dev/null || true)"
# resolved through realpath before comparing - /etc/shells or chsh may record a
# symlinked path (e.g. /usr/bin/zsh -> zsh-5.9) that wouldn't string-match $_zsh_path
_configured_real="$(realpath "$_configured_shell" 2>/dev/null || echo "$_configured_shell")"
_zsh_real="$(realpath "$_zsh_path" 2>/dev/null || echo "$_zsh_path")"
if [ -n "$_zsh_path" ] && [ "$_configured_real" = "$_zsh_real" ]; then
    _pass "zsh is the default shell  (${_zsh_path})"
else
    _fail "zsh is not the default shell  (current: ${_configured_shell:-unknown})"
fi

# ─────────────────────────────────────────
# Version Control
# ─────────────────────────────────────────

section "Version Control"

if command -v git >/dev/null 2>&1; then
    _git_ver="$(git --version 2>/dev/null | awk '{print $3}')"
    _pass "git  ${_git_ver}"
else
    _fail "git  not found"
fi

if command -v git-lfs >/dev/null 2>&1; then
    _lfs_ver="$(git-lfs version 2>/dev/null | sed 's/git-lfs\///' | awk '{print $1}')"
    _pass "git-lfs  ${_lfs_ver}"
else
    _fail "git-lfs  not found"
fi

if command -v git-lfs >/dev/null 2>&1; then
    # filter.lfs.required is pre-seeded in the tracked .gitconfig and always reads true,
    # so it can't tell us whether hooks are actually registered - check core.hooksPath is
    # set in .gitconfig.local (never --global; that would write into the tracked .gitconfig)
    # and that the hook file actually exists there
    _git_hooks_dir="$(git config --file "${HOME}/.gitconfig.local" core.hooksPath 2>/dev/null || true)"
    if [ -n "$_git_hooks_dir" ] && [ -f "${_git_hooks_dir}/pre-push" ]; then
        _pass "git-lfs hooks registered"
    else
        _fail "git-lfs hooks not registered  (fix: ./run.sh setup_git_lfs)"
    fi
fi

_git_local="${HOME}/.gitconfig.local"
_git_name="$(git config --file "$_git_local" user.name 2>/dev/null || true)"
_git_email="$(git config --file "$_git_local" user.email 2>/dev/null || true)"
if [ -n "$_git_name" ]; then
    _pass "git identity: name  ${_git_name}"
else
    _fail "git identity: name not configured in ~/.gitconfig.local"
fi
if [ -n "$_git_email" ]; then
    _pass "git identity: email  ${_git_email}"
else
    _fail "git identity: email not configured in ~/.gitconfig.local"
fi

# ─────────────────────────────────────────
# Plugin Manager (zinit)
# ─────────────────────────────────────────

section "Plugin Manager (zinit)"

_zinit_home="${HOME}/.local/share/zinit/zinit.git"
if [ -d "$_zinit_home" ]; then
    _pass "zinit installed  (${_zinit_home})"
else
    _fail "zinit not found  (${_zinit_home})"
fi

_zinit_plugins="${HOME}/.local/share/zinit/plugins"
for _plugin in \
    "zsh-users---zsh-completions" \
    "zsh-users---zsh-autosuggestions" \
    "zsh-users---zsh-syntax-highlighting" \
    "romkatv---powerlevel10k"
do
    if [ -d "${_zinit_plugins}/${_plugin}" ]; then
        _pass "zinit plugin: ${_plugin}"
    else
        _pending "zinit plugin pending: ${_plugin}  (downloads on first shell launch)"
    fi
done

# ─────────────────────────────────────────
# Node.js
# ─────────────────────────────────────────

section "Node.js"

# kept in sync with .zshrc's NVM_DIR and setup_nvm's NVM_DIR - see .zshrc's comment
_nvm_dir="${HOME}/.nvm"
if [ -s "${_nvm_dir}/nvm.sh" ]; then
    _pass "nvm installed  (${_nvm_dir})"
else
    _fail "nvm not found  (${_nvm_dir}/nvm.sh missing)"
fi

if [ -f "${_nvm_dir}/alias/default" ] && [ -s "${_nvm_dir}/alias/default" ]; then
    _nvm_default="$(cat "${_nvm_dir}/alias/default")"
    _pass "nvm default alias set  (${_nvm_default})"
else
    _fail "nvm default alias not configured"
fi

# source nvm to resolve node/npm versions
set +u
# shellcheck disable=SC1091
[ -s "${_nvm_dir}/nvm.sh" ] && \. "${_nvm_dir}/nvm.sh"
set -u

if command -v node >/dev/null 2>&1; then
    _node_ver="$(node --version 2>/dev/null)"
    _pass "node  ${_node_ver}"
else
    _fail "node  not found  (nvm may need a terminal restart)"
fi

if command -v npm >/dev/null 2>&1; then
    _npm_ver="$(npm --version 2>/dev/null)"
    _pass "npm  ${_npm_ver}"
else
    _fail "npm  not found"
fi

if command -v pnpm >/dev/null 2>&1; then
    _pnpm_ver="$(pnpm --version 2>/dev/null)"
    _pass "pnpm  ${_pnpm_ver}"
else
    _fail "pnpm  not found"
fi

# ─────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────

section "Utilities"

if command -v tree >/dev/null 2>&1; then
    _tree_ver="$(tree --version 2>/dev/null | awk '{print $2}')"
    _pass "tree  ${_tree_ver}"
else
    _fail "tree  not found"
fi

if command -v fzf >/dev/null 2>&1; then
    _fzf_ver="$(fzf --version 2>/dev/null | awk '{print $1}')"
    _pass "fzf  ${_fzf_ver}"
else
    _fail "fzf  not found"
fi

if command -v zoxide >/dev/null 2>&1; then
    _zox_ver="$(zoxide --version 2>/dev/null | awk '{print $2}')"
    _pass "zoxide  ${_zox_ver}"
else
    _fail "zoxide  not found"
fi

if command -v rg >/dev/null 2>&1; then
    _rg_ver="$(rg --version 2>/dev/null | head -1 | awk '{print $2}')"
    _pass "ripgrep  ${_rg_ver}"
else
    _fail "ripgrep (rg)  not found"
fi

_bat_cmd="$(_bat_binary_name)"
if command -v "$_bat_cmd" >/dev/null 2>&1; then
    _bat_ver="$("$_bat_cmd" --version 2>/dev/null | awk '{print $2}')"
    _pass "bat  ${_bat_ver}  (${_bat_cmd})"
else
    _fail "bat  not found  (expected: ${_bat_cmd})"
fi

if command -v lazygit >/dev/null 2>&1; then
    _lg_ver="$(lazygit --version 2>/dev/null | sed 's/.*version=\([^,]*\).*/\1/')"
    _pass "lazygit  ${_lg_ver}"
else
    _fail "lazygit  not found"
fi

if command -v gh >/dev/null 2>&1; then
    _gh_ver="$(gh --version 2>/dev/null | head -1 | awk '{print $3}')"
    _pass "gh (GitHub CLI)  ${_gh_ver}"
else
    _fail "gh (GitHub CLI)  not found"
fi

# ─────────────────────────────────────────
# Dotfiles (Symlinks)
# ─────────────────────────────────────────

section "Dotfiles (Symlinks)"

# thin wrapper around the shared _symlink_status() (scripts/helpers.sh) that maps
# each status to this script's own _pass/_fail message text
_check_symlink() {
    local dest="$1" src="$2" label="$3"
    local _status
    _status="$(_symlink_status "$dest" "$src")"
    case "$_status" in
        linked)       _pass "${label}  → ${src}" ;;
        broken:*)     _fail "${label}  broken symlink (points to: ${_status#broken:})" ;;
        regular-file) _fail "${label}  exists as a regular file, not a symlink" ;;
        missing)      _fail "${label}  not found" ;;
    esac
}

_check_symlink "${HOME}/.zshenv"    "${DOTFILES_DIR}/.zshenv"    "~/.zshenv"
_check_symlink "${HOME}/.zshrc"     "${DOTFILES_DIR}/.zshrc"     "~/.zshrc"
_check_symlink "${HOME}/.gitconfig" "${DOTFILES_DIR}/.gitconfig" "~/.gitconfig"
_check_symlink "${HOME}/.p10k.zsh"  "${DOTFILES_DIR}/.p10k.zsh"  "~/.p10k.zsh"

_claude_settings="${HOME}/.claude/settings.json"
_claude_src="${DOTFILES_DIR}/claude/settings.json"
if [ -L "$_claude_settings" ] && [ "$(readlink "$_claude_settings")" = "$_claude_src" ]; then
    _pass "~/.claude/settings.json  → ${_claude_src}"
elif [ -e "$_claude_settings" ]; then
    _warn "~/.claude/settings.json  exists but is not linked to dotfiles"
else
    _warn "~/.claude/settings.json  not linked  (personal machine only)"
fi

# the settings.json symlink check above only proves the config is wired up, not that
# the CLI itself is actually installed (e.g. a silently-failed npm install would still
# pass that check) - so check the binary too
if command -v claude >/dev/null 2>&1; then
    _claude_ver="$(claude --version 2>/dev/null | awk '{print $1}')"
    _pass "Claude Code CLI  ${_claude_ver}"
else
    _warn "Claude Code CLI  not installed  (personal machine only)"
fi

# ─────────────────────────────────────────
# PATH
# ─────────────────────────────────────────

section "PATH"

if printf '%s\n' "${PATH//:/$'\n'}" | grep -qx "${HOME}/.local/bin"; then
    _pass "~/.local/bin  in PATH"
else
    _fail "~/.local/bin  not in PATH"
fi

if [ "$OS" = "macos" ]; then
    # Apple Silicon installs to /opt/homebrew, Intel to /usr/local - accept either
    if [ -x /opt/homebrew/bin/brew ]; then
        _brew_prefix="/opt/homebrew/bin"
    elif [ -x /usr/local/bin/brew ]; then
        _brew_prefix="/usr/local/bin"
    else
        _brew_prefix=""
    fi
    if [ -n "$_brew_prefix" ] && printf '%s\n' "${PATH//:/$'\n'}" | grep -qx "$_brew_prefix"; then
        _pass "${_brew_prefix}  in PATH"
    else
        _fail "Homebrew bin dir not in PATH  (expected /opt/homebrew/bin or /usr/local/bin)"
    fi
fi

# ─────────────────────────────────────────
# Shell Init Caches
# ─────────────────────────────────────────

section "Shell Init Caches"

_fzf_cache="${XDG_CACHE_HOME:-${HOME}/.cache}/fzf.zsh"
if [ -f "$_fzf_cache" ]; then
    _pass "fzf init cache  (${_fzf_cache})"
else
    _pending "fzf init cache  (generated on first shell launch)"
fi

_zoxide_cache="${XDG_CACHE_HOME:-${HOME}/.cache}/zoxide.zsh"
if [ -f "$_zoxide_cache" ]; then
    _pass "zoxide init cache  (${_zoxide_cache})"
else
    _pending "zoxide init cache  (generated on first shell launch)"
fi

_gpg_ssh_sock_cache="${XDG_CACHE_HOME:-${HOME}/.cache}/gpg-ssh-socket.txt"
if [ -f "$_gpg_ssh_sock_cache" ]; then
    _pass "gpg SSH-socket cache  (${_gpg_ssh_sock_cache})"
else
    _pending "gpg SSH-socket cache  (generated on first shell launch, personal machines only)"
fi

# ─────────────────────────────────────────
# Startup Time
# ─────────────────────────────────────────

section "Startup Time"

# informational only, not a pass/fail check - there's no threshold that's meaningful
# across arbitrary machines (disk speed, cold vs warm cache), just a number to track
if command -v zsh >/dev/null 2>&1; then
    _startup_s="$( { /usr/bin/time -p zsh -i -c exit; } 2>&1 | awk '/^real/{print $2}' )"
    if [ -n "$_startup_s" ]; then
        note "Interactive shell startup: ${_startup_s}s  (run again after opening a fresh terminal for a warm-cache reading)"
    fi
fi

# ─────────────────────────────────────────
# Security (warn-only - optional on non-personal machines)
# ─────────────────────────────────────────

section "Security"

if command -v gpg >/dev/null 2>&1; then
    _gpg_ver="$(gpg --version 2>/dev/null | head -1 | awk '{print $3}')"
    _pass "gpg  ${_gpg_ver}"
else
    _warn "gpg  not installed  (personal machine only)"
fi

if command -v gpg >/dev/null 2>&1 && gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep -q '^sec'; then
    _gpg_key_id="$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | awk -F'/' '/^sec/{print $2}' | awk '{print $1}' | head -1)"
    _pass "GPG secret key configured  (${_gpg_key_id})"
else
    _warn "GPG secret key  not configured  (personal machine only)"
fi

if [ -f "${HOME}/.ssh/id_ed25519.pub" ]; then
    _ssh_fp="$(ssh-keygen -lf "${HOME}/.ssh/id_ed25519.pub" 2>/dev/null | awk '{print $2}')"
    _pass "SSH key  ${_ssh_fp}"
else
    _warn "SSH key not found at ~/.ssh/id_ed25519.pub  (personal machine only)"
fi

if [ -f "${HOME}/.gnupg/gpg-agent.conf" ]; then
    _pass "gpg-agent.conf configured"
    if grep -q "default-cache-ttl-ssh" "${HOME}/.gnupg/gpg-agent.conf" 2>/dev/null; then
        _pass "gpg-agent SSH cache TTL configured"
    else
        _warn "gpg-agent SSH cache TTL not set  (fix: ./run.sh setup_gpg_agent_conf)"
    fi
    # gpg-agent.conf recording a pinentry-program path doesn't prove that binary still
    # exists (e.g. a Homebrew upgrade can move it) - check the recorded path directly
    _pinentry_path="$(awk '/^pinentry-program/{print $2}' "${HOME}/.gnupg/gpg-agent.conf" 2>/dev/null)"
    if [ -n "$_pinentry_path" ] && [ -x "$_pinentry_path" ]; then
        _pass "pinentry  ${_pinentry_path}"
    else
        _warn "pinentry  not found at configured path (${_pinentry_path:-none})  (fix: ./run.sh setup_gpg_agent_conf)"
    fi
else
    _warn "gpg-agent.conf not found  (personal machine only)"
fi

if command -v gpgconf >/dev/null 2>&1; then
    if [ -f "${HOME}/.gnupg/gpg-agent.conf" ] && grep -q "enable-ssh-support" "${HOME}/.gnupg/gpg-agent.conf" 2>/dev/null; then
        _gpg_ssh_sock="$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null)"
        # ssh-add -l exit code 2 = cannot connect; 0 = keys present; 1 = agent alive, no keys
        _gpg_keys="$(SSH_AUTH_SOCK="$_gpg_ssh_sock" ssh-add -l 2>&1)"
        _gpg_exit=$?
        if [ "$_gpg_exit" -ne 2 ]; then
            _pass "gpg-agent SSH socket active"
            if [ -f "${HOME}/.ssh/id_ed25519.pub" ]; then
                _ssh_fp="$(ssh-keygen -lf "${HOME}/.ssh/id_ed25519.pub" 2>/dev/null | awk '{print $2}')"
                if echo "$_gpg_keys" | grep -qF "$_ssh_fp"; then
                    _pass "SSH key loaded in gpg-agent"
                else
                    _warn "SSH key not loaded in gpg-agent  (fix: ssh-add ~/.ssh/id_ed25519)"
                fi
            fi
        else
            _fail "gpg-agent not responding  (fix: open a new terminal, or run: source ~/.zshrc)"
        fi
    fi
fi

# ─────────────────────────────────────────
# Repo Tooling (warn-only - only needed to develop/test this repo itself,
# not for using it to bootstrap a machine)
# ─────────────────────────────────────────

section "Repo Tooling"

if command -v bats >/dev/null 2>&1; then
    _bats_ver="$(bats --version 2>/dev/null | awk '{print $2}')"
    _pass "bats  ${_bats_ver}"
else
    _warn "bats  not installed  (only needed to run this repo's own tests - fix: ./run.sh setup_bats)"
fi

if command -v shellcheck >/dev/null 2>&1; then
    _shellcheck_ver="$(shellcheck --version 2>/dev/null | awk '/^version:/{print $2}')"
    _pass "shellcheck  ${_shellcheck_ver}"
else
    _warn "shellcheck  not installed  (only needed to lint this repo's own scripts - fix: ./run.sh setup_shellcheck)"
fi

# ─────────────────────────────────────────
# Summary
# ─────────────────────────────────────────

echo ""
printf "  ${BOLD_CYAN}════════════════════════════════════════════════════${RESET}\n"
if [ "$_FAIL" -eq 0 ] && [ "$_WARN" -eq 0 ]; then
    printf "  ${BOLD_GREEN}✓${RESET}  ${BOLD_WHITE}All checks passed${RESET}  ${DIM}(${_PASS} ok, 0 warnings, 0 failed)${RESET}\n"
elif [ "$_FAIL" -eq 0 ]; then
    printf "  ${YELLOW}⚠${RESET}  ${BOLD_WHITE}Checks passed with warnings${RESET}  ${DIM}(${_PASS} ok, ${_WARN} warnings, 0 failed)${RESET}\n"
else
    printf "  ${BOLD_RED}✗${RESET}  ${BOLD_WHITE}${_FAIL} check(s) failed${RESET}  ${DIM}(${_PASS} ok, ${_WARN} warnings, ${_FAIL} failed)${RESET}\n"
fi
printf "  ${BOLD_CYAN}════════════════════════════════════════════════════${RESET}\n"
echo ""

[ "$_FAIL" -eq 0 ]
