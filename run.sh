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
        printf "  ${DIM}Select one or more, e.g. 3 | 1,4,7 | 1-6${RESET}\n"
        printf "  Select: "
        read -r _choice || break
        echo ""

        case "$_choice" in
            q|Q) break ;;
            c|C) bash "${DOTFILES_DIR}/check.sh" || true ;;
            *) _run_selection "$_choice" ;;
        esac
        echo ""
    done
}

# parses a multi-select list - comma/space separated numbers and/or N-M ranges
# (e.g. "3", "1,4,7", "1 4 7", "1-6", "1-3,7,10-12") - against the menu's _names array.
# functions are idempotent, so a duplicate selection just re-runs harmlessly rather than
# needing to be deduped. Validates the whole list before running anything, so a typo
# can't trigger a partial run of only the tokens that happened to parse.
_run_selection() {
    local _input="$1"
    local _selected=() _valid=true _token _range_start _range_end _n

    for _token in $(echo "$_input" | tr ',' ' '); do
        case "$_token" in
            *-*)
                _range_start="${_token%%-*}"
                _range_end="${_token##*-}"
                case "$_range_start" in ''|*[!0-9]*) _valid=false ;; esac
                case "$_range_end" in ''|*[!0-9]*) _valid=false ;; esac
                # reject out-of-range bounds here rather than expanding a huge range
                # and spamming one "invalid" warning per out-of-bounds number below
                if [ "$_valid" = true ] && [ "$_range_end" -gt "${#_names[@]}" ]; then
                    _valid=false
                fi
                if [ "$_valid" = true ] && [ "$_range_start" -le "$_range_end" ]; then
                    for ((_n = _range_start; _n <= _range_end; _n++)); do
                        _selected+=("$_n")
                    done
                else
                    _valid=false
                fi
                ;;
            ''|*[!0-9]*) _valid=false ;;
            *) _selected+=("$_token") ;;
        esac
        [ "$_valid" = true ] || break
    done

    if [ "$_valid" != true ] || [ "${#_selected[@]}" -eq 0 ]; then
        warn "Invalid selection: ${_input}"
        return
    fi

    for _n in "${_selected[@]}"; do
        if [ -n "${_names[$_n]:-}" ]; then
            "${_names[$_n]}" || warn "${_names[$_n]} exited with an error - see output above."
        else
            warn "Invalid selection: ${_n}"
        fi
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
