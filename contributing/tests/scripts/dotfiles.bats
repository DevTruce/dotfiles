#!/usr/bin/env bats
# Unit tests for setup_dotfiles() in scripts/dotfiles.sh. Runs the real function
# end-to-end against a fixture $HOME and $DOTFILES_DIR (both temp dirs) - never
# touches the real machine's actual dotfiles.

setup() {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../../scripts/helpers.sh"
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../../scripts/dotfiles.sh"

  _FAKE_HOME="$(mktemp -d)"
  _FAKE_DOTFILES="$(mktemp -d)"
  for _f in .zshenv .zshrc .gitconfig .p10k.zsh; do
    echo "fixture content for ${_f}" > "${_FAKE_DOTFILES}/${_f}"
  done
  mkdir -p "${_FAKE_DOTFILES}/claude"
  echo '{"fixture": true}' > "${_FAKE_DOTFILES}/claude/settings.json"

  HOME="$_FAKE_HOME"
  DOTFILES_DIR="$_FAKE_DOTFILES"
  PERSONAL_MACHINE="n"
}

teardown() {
  rm -rf "$_FAKE_HOME" "$_FAKE_DOTFILES"
}

@test "symlinks all four core dotfiles into a fresh HOME" {
  run setup_dotfiles
  [ "$status" -eq 0 ]
  for _f in .zshenv .zshrc .gitconfig .p10k.zsh; do
    [ -L "${_FAKE_HOME}/${_f}" ]
    [ "$(readlink "${_FAKE_HOME}/${_f}")" = "${_FAKE_DOTFILES}/${_f}" ]
  done
}

@test "backs up a pre-existing regular file instead of overwriting it" {
  echo "user's real pre-existing content" > "${_FAKE_HOME}/.zshrc"
  run setup_dotfiles
  [ -f "${_FAKE_HOME}/.zshrc.bak" ]
  [ "$(cat "${_FAKE_HOME}/.zshrc.bak")" = "user's real pre-existing content" ]
  [ -L "${_FAKE_HOME}/.zshrc" ]
}

@test "re-running when already linked makes no changes and reports 'already linked'" {
  setup_dotfiles >/dev/null
  local _before
  _before="$(readlink "${_FAKE_HOME}/.zshrc")"
  run setup_dotfiles
  [[ "$output" == *"already linked"* ]]
  [ "$(readlink "${_FAKE_HOME}/.zshrc")" = "$_before" ]
}

@test "does not symlink claude/settings.json when PERSONAL_MACHINE is not y" {
  PERSONAL_MACHINE="n"
  run setup_dotfiles
  [ ! -e "${_FAKE_HOME}/.claude/settings.json" ]
}

@test "symlinks claude/settings.json when PERSONAL_MACHINE=y" {
  PERSONAL_MACHINE="y"
  run setup_dotfiles
  [ -L "${_FAKE_HOME}/.claude/settings.json" ]
  [ "$(readlink "${_FAKE_HOME}/.claude/settings.json")" = "${_FAKE_DOTFILES}/claude/settings.json" ]
}

@test "relinks a symlink that points at the wrong target" {
  ln -s "/some/unrelated/path" "${_FAKE_HOME}/.gitconfig"
  run setup_dotfiles
  [ "$(readlink "${_FAKE_HOME}/.gitconfig")" = "${_FAKE_DOTFILES}/.gitconfig" ]
}
