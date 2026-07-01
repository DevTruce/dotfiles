#!/usr/bin/env bash
set -uo pipefail

# BASH_SOURCE[0] (not $0) so this still resolves correctly if ever sourced instead
# of executed directly
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
. "${DOTFILES_DIR}/scripts/helpers.sh"

# ─────────────────────────────────────────
# Check Counters
# ─────────────────────────────────────────

_PASS=0
_FAIL=0
_WARN=0

_pass() { ok   "$1"; _PASS=$((_PASS + 1)); }
_fail() { fail "$1"; _FAIL=$((_FAIL + 1)); }
_warn() { warn "$1"; _WARN=$((_WARN + 1)); }

# ─────────────────────────────────────────
# Header
# ─────────────────────────────────────────

# skipped when run under ci.sh (_FROM_CI_SH=1), since the per-file sections and
# closing summary below already announce this phase - standalone `./test.sh`
# still gets this banner
if [ -z "${_FROM_CI_SH:-}" ]; then
    echo ""
    printf "  ${BOLD_CYAN}┌──────────────────────────────────────────────────────┐${RESET}\n"
    printf "  ${BOLD_CYAN}│${RESET}  ${BOLD_WHITE}%-52s${RESET}${BOLD_CYAN}│${RESET}\n" "Test Suite"
    printf "  ${BOLD_CYAN}└──────────────────────────────────────────────────────┘${RESET}\n"
    echo ""
fi

if ! command -v bats >/dev/null 2>&1; then
    fail "bats not found  (fix: ~/dev-bootstrap/run.sh setup_bats)"
    echo ""
    exit 1
fi

# ─────────────────────────────────────────
# Run every tests/**/*.bats file, grouped by file (mirrors doctor.sh's section-per-
# category convention). Each bats result is re-emitted through this repo's own
# ok()/fail()/warn() instead of bats' default TAP/pretty output, so a passing test
# is a green check, a failing test a red X, and a skipped test (bats `skip "reason"`)
# a yellow warning - the natural analog to "non-blocking" in this repo's convention.
# ─────────────────────────────────────────

while IFS= read -r _bats_file; do
    _rel="${_bats_file#"${DOTFILES_DIR}"/tests/}"
    _rel="${_rel%.bats}"
    section "$_rel"

    while IFS= read -r _line; do
        if [[ "$_line" =~ ^not\ ok\ [0-9]+\ (.*)$ ]]; then
            _fail "${BASH_REMATCH[1]}"
        elif [[ "$_line" =~ ^ok\ [0-9]+\ (.*)$ ]]; then
            _desc="${BASH_REMATCH[1]}"
            if [[ "$_desc" == *" # skip"* ]]; then
                _warn "${_desc%% # skip*}"
            else
                _pass "$_desc"
            fi
        fi
        # anything else (the "1..N" plan line, indented failure diagnostics) is
        # TAP scaffolding, not a test result - ignored
    done < <(bats --tap "$_bats_file")
done < <(find "${DOTFILES_DIR}/tests" -name '*.bats' | sort)

# ─────────────────────────────────────────
# Summary
# ─────────────────────────────────────────

echo ""
printf "  ${BOLD_CYAN}════════════════════════════════════════════════════${RESET}\n"
if [ "$_FAIL" -eq 0 ] && [ "$_WARN" -eq 0 ]; then
    printf "  ${BOLD_GREEN}✓${RESET}  ${BOLD_WHITE}All tests passed${RESET}  ${DIM}(${_PASS} ok, 0 warnings, 0 failed)${RESET}\n"
elif [ "$_FAIL" -eq 0 ]; then
    printf "  ${YELLOW}⚠${RESET}  ${BOLD_WHITE}Tests passed with warnings${RESET}  ${DIM}(${_PASS} ok, ${_WARN} warnings, 0 failed)${RESET}\n"
else
    printf "  ${BOLD_RED}✗${RESET}  ${BOLD_WHITE}${_FAIL} test(s) failed${RESET}  ${DIM}(${_PASS} ok, ${_WARN} warnings, ${_FAIL} failed)${RESET}\n"
fi
printf "  ${BOLD_CYAN}════════════════════════════════════════════════════${RESET}\n"
echo ""

[ "$_FAIL" -eq 0 ]
