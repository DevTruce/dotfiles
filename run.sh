#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="${HOME}/.local/bin:${PATH}"

# ─────────────────────────────────────────
# Bootstrap
# ─────────────────────────────────────────

# -- Load all setup functions
for f in "${DOTFILES_DIR}/scripts/"*.sh; do
    # shellcheck source=/dev/null
    . "$f"
done

# -- Detect OS
OS="$(detect_os)"

# run.sh always runs exactly one explicitly-chosen function, unlike install.sh's "do you
# want the personal bundle or just core" prompt over a whole batch - choosing to run a
# personal-only function (e.g. setup_ssh_key) already is the consent, so there's nothing
# to ask. Only setup_dotfiles reads this (to also symlink claude/settings.json).
PERSONAL_MACHINE="y"

# ─────────────────────────────────────────
# Interactive menu (bash run.sh, no arguments)
# ─────────────────────────────────────────

# category|function|description entries, in display order. Plain indexed array (not
# declare -A) since macOS ships bash 3.2 by default, which has no associative arrays.
_MENU_ITEMS=(
    "Package Manager|setup_homebrew|Install/update Homebrew (macOS)"
    "Package Manager|setup_apt|Install/update apt packages (Linux)"
    "Shell|setup_zsh|Install zsh and set it as the default shell"
    "Version Control|setup_git|Install git and configure your local identity"
    "Version Control|setup_git_lfs|Install git-lfs and register its hooks globally"
    "Plugin Manager|setup_zsh_plugins|Install the zinit zsh plugin manager"
    "Node.js|setup_nvm|Install nvm (Node Version Manager) and Node LTS"
    "Node.js|setup_pnpm|Install pnpm"
    "Utilities|setup_tree|Install tree"
    "Utilities|setup_fzf|Install fzf (fuzzy finder)"
    "Utilities|setup_zoxide|Install zoxide (smart cd)"
    "Utilities|setup_ripgrep|Install ripgrep"
    "Utilities|setup_bat|Install bat"
    "Utilities|setup_lazygit|Install lazygit"
    "Utilities|setup_gh|Install GitHub CLI"
    "Dotfiles|setup_dotfiles|Symlink dotfiles into your home directory"
    "Security (personal)|setup_gpg_tools|Install gpg"
    "Security (personal)|setup_ssh_key|Generate an SSH key and register it with gpg-agent"
    "Security (personal)|setup_gpg_key|Generate a GPG key and configure commit signing"
    "Security (personal)|setup_gpg_agent_conf|Configure gpg-agent (pinentry, cache TTLs)"
    "Security (personal)|setup_claude|Install the Claude Code CLI"
)

_run_interactive() {
    # built once: parallel array so a numeric selection can look up its function name
    # (indexed arrays only - see the bash 3.2 note above)
    local _names=()
    local _entry _category _name _desc _i

    while true; do
        printf "  ${BOLD_CYAN}┌──────────────────────────────────────────────────────┐${RESET}\n"
        printf "  ${BOLD_CYAN}│${RESET}  ${BOLD_WHITE}%-52s${RESET}${BOLD_CYAN}│${RESET}\n" "Run a setup function"
        printf "  ${BOLD_CYAN}└──────────────────────────────────────────────────────┘${RESET}\n"

        _names=()
        _i=1
        local _last_category=""
        for _entry in "${_MENU_ITEMS[@]}"; do
            IFS='|' read -r _category _name _desc <<< "$_entry"
            # setup_homebrew/setup_apt are the only truly OS-exclusive functions (both
            # refuse to run on the wrong OS anyway) - skip showing the inapplicable one
            # rather than let it appear and fail
            case "$_name" in
                setup_homebrew) [ "$OS" = "macos" ] || continue ;;
                setup_apt)      [ "$OS" != "macos" ] || continue ;;
            esac
            if [ "$_category" != "$_last_category" ]; then
                printf "\n  ${DIM}%s${RESET}\n" "$_category"
                _last_category="$_category"
            fi
            printf "  ${CYAN}%2d)${RESET}  %-22s ${DIM}%s${RESET}\n" "$_i" "$_name" "$_desc"
            _names[$_i]="$_name"
            _i=$((_i + 1))
        done

        printf "\n  ${CYAN} c)${RESET}  Run check.sh ${DIM}(verify current setup)${RESET}\n"
        printf "  ${CYAN} q)${RESET}  Quit\n\n"
        printf "  Select: "
        read -r _choice || break
        echo ""

        case "$_choice" in
            q|Q) break ;;
            c|C) bash "${DOTFILES_DIR}/check.sh" || true ;;
            ''|*[!0-9]*) warn "Invalid selection: ${_choice}" ;;
            *)
                if [ -n "${_names[$_choice]:-}" ]; then
                    "${_names[$_choice]}" || warn "${_names[$_choice]} exited with an error - see output above."
                else
                    warn "Invalid selection: ${_choice}"
                fi
                ;;
        esac
        echo ""
    done
}

# ─────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────

if [ $# -eq 0 ]; then
    _run_interactive
    exit 0
fi

if ! declare -f "$1" >/dev/null 2>&1; then
    warn "Unknown function: $1"
    exit 1
fi

"$1"
