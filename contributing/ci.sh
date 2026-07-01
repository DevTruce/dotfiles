#!/usr/bin/env bash
set -uo pipefail

# BASH_SOURCE[0] (not $0) so this still resolves correctly if ever sourced instead
# of executed directly. One level up from contributing/ to the repo root.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
. "${DOTFILES_DIR}/scripts/helpers.sh"

_FAIL=0

echo ""
printf "  ${BOLD_CYAN}┌──────────────────────────────────────────────────────┐${RESET}\n"
printf "  ${BOLD_CYAN}│${RESET}  ${BOLD_WHITE}%-52s${RESET}${BOLD_CYAN}│${RESET}\n" "Full Check (matches CI)"
printf "  ${BOLD_CYAN}└──────────────────────────────────────────────────────┘${RESET}\n"

# _FROM_CI_SH tells test.sh to skip its own "Test Suite" banner; test.sh's own
# per-file sections and closing summary already announce this phase, so a
# wrapping "▸ Tests" header here would be a redundant, contentless header.
_FROM_CI_SH=1 "${DOTFILES_DIR}/contributing/test.sh" || _FAIL=$((_FAIL + 1))

section "Lint"
if ! command -v shellcheck >/dev/null 2>&1; then
    warn "shellcheck not installed  (fix: ~/dev-bootstrap/run.sh setup_shellcheck)"
    _FAIL=$((_FAIL + 1))
# --exclude, not --rcfile: shellcheck's .shellcheckrc auto-discovery walks up from each
# target file's own directory, never sideways - a contributing/.shellcheckrc would never
# apply to root-level or scripts/*.sh files no matter how it's invoked. --rcfile itself is
# also unsupported by ShellCheck 0.9.0 (Ubuntu 24.04/GitHub Actions' preinstalled version).
# SC2148: scripts/*.sh are sourced only, never executed - no shebang by design.
# SC2088: "~/path" strings here are literal display text, not paths meant to expand.
elif (cd "$DOTFILES_DIR" && shellcheck --exclude=SC2148,SC2088 --severity=warning *.sh scripts/*.sh contributing/*.sh); then
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
