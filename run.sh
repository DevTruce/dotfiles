#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─────────────────────────────────────────
# Bootstrap
# ─────────────────────────────────────────

if [ $# -eq 0 ]; then
    echo "  Usage: bash run.sh <function_name>"
    echo "  e.g.   bash run.sh setup_gpg_key"
    exit 1
fi

# -- Load all setup functions
for f in "${DOTFILES_DIR}/scripts/"*.sh; do
    # shellcheck source=/dev/null
    . "$f"
done

# -- Detect OS
OS="$(detect_os)"

# -- Personal machine prompt
printf "  Is this a personal machine? (y/N): "
read -r _reply
case "$_reply" in
    [Yy]) PERSONAL_MACHINE="y" ;;
    *)    PERSONAL_MACHINE="n" ;;
esac
echo ""

# ─────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────

if ! declare -f "$1" >/dev/null 2>&1; then
    echo "  Unknown function: $1"
    exit 1
fi

"$1"
