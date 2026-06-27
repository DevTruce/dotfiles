#!/usr/bin/env bash
set -euo pipefail

# Usage: bash ~/dotfiles/run.sh <function_name>
#   e.g. bash ~/dotfiles/run.sh setup_gpg_key

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -eq 0 ]; then
    echo "  Usage: bash run.sh <function_name>"
    echo "  e.g.   bash run.sh setup_gpg_key"
    exit 1
fi

for f in "${DOTFILES_DIR}/scripts/"*.sh; do
    # shellcheck source=/dev/null
    . "$f"
done

OS="$(detect_os)"

printf "  Is this a personal machine? (y/N): "
read -r _reply
case "$_reply" in
    [Yy]) PERSONAL_MACHINE="y" ;;
    *)    PERSONAL_MACHINE="n" ;;
esac
echo ""

if ! declare -f "$1" >/dev/null 2>&1; then
    echo "  Unknown function: $1"
    exit 1
fi

"$1"
