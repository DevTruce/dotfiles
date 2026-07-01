#!/usr/bin/env bash
set -uo pipefail

# BASH_SOURCE[0] (not $0) so this still resolves correctly if ever sourced instead
# of executed directly
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
. "${DOTFILES_DIR}/scripts/helpers.sh"

_FAIL=0

echo ""
printf "  ${BOLD_CYAN}┌──────────────────────────────────────────────────────┐${RESET}\n"
printf "  ${BOLD_CYAN}│${RESET}  ${BOLD_WHITE}%-52s${RESET}${BOLD_CYAN}│${RESET}\n" "Full Check (matches CI)"
printf "  ${BOLD_CYAN}└──────────────────────────────────────────────────────┘${RESET}\n"

section "Tests"
"${DOTFILES_DIR}/test.sh" || _FAIL=$((_FAIL + 1))

section "Lint"
if ! command -v shellcheck >/dev/null 2>&1; then
    warn "shellcheck not installed  (fix: ./run.sh setup_shellcheck)"
    _FAIL=$((_FAIL + 1))
elif (cd "$DOTFILES_DIR" && shellcheck --severity=warning *.sh scripts/*.sh); then
    ok "shellcheck passed"
else
    fail "shellcheck failed"
    _FAIL=$((_FAIL + 1))
fi

section "Zsh syntax"
if (cd "$DOTFILES_DIR" && zsh -n .zshrc && zsh -n .zshenv && zsh -n .p10k.zsh); then
    ok "zsh -n passed"
else
    fail "zsh syntax check failed"
    _FAIL=$((_FAIL + 1))
fi

echo ""
printf "  ${BOLD_CYAN}════════════════════════════════════════════════════${RESET}\n"
if [ "$_FAIL" -eq 0 ]; then
    printf "  ${BOLD_GREEN}✓${RESET}  ${BOLD_WHITE}All checks passed${RESET}\n"
else
    printf "  ${BOLD_RED}✗${RESET}  ${BOLD_WHITE}${_FAIL} check(s) failed${RESET}\n"
fi
printf "  ${BOLD_CYAN}════════════════════════════════════════════════════${RESET}\n"
echo ""

[ "$_FAIL" -eq 0 ]
