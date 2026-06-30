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

# ─────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────

if [ $# -eq 0 ]; then
    printf "  Usage:  bash run.sh <function_name>\n"
    printf "  ${DIM}e.g.    bash run.sh setup_gpg_key${RESET}\n"
    exit 1
fi

if ! declare -f "$1" >/dev/null 2>&1; then
    warn "Unknown function: $1"
    exit 1
fi

# -- Personal machine prompt
printf "  ${CYAN}?${RESET}  Is this a personal machine? ${DIM}(y/N)${RESET}: "
read -r _reply
case "$_reply" in
    [Yy]) PERSONAL_MACHINE="y" ;;
    *)    PERSONAL_MACHINE="n" ;;
esac
echo ""

"$1"
