#!/usr/bin/env bats
# Unit tests for setup_git()'s identity-prompt and editor-selection logic in
# scripts/version-control.sh. Safe to run for real because `command -v git` is
# assumed to succeed (true on any dev/CI box), so the "install git" branch never
# triggers - only the prompt/config logic below it is exercised, against a fixture
# $HOME so the real ~/.gitconfig.local is never touched.

setup() {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../scripts/helpers.sh"
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../scripts/version-control.sh"

  _FAKE_HOME="$(mktemp -d)"
  HOME="$_FAKE_HOME"
  _GITCONFIG_LOCAL="${_FAKE_HOME}/.gitconfig.local"
}

teardown() {
  rm -rf "$_FAKE_HOME"
}

@test "saves name, email, and editor choice from prompts on a fresh identity" {
  run setup_git <<< $'Jane Doe\njane@example.com\n2\n'
  [ "$status" -eq 0 ]
  [ "$(git config --file "$_GITCONFIG_LOCAL" user.name)" = "Jane Doe" ]
  [ "$(git config --file "$_GITCONFIG_LOCAL" user.email)" = "jane@example.com" ]
  [ "$(git config --file "$_GITCONFIG_LOCAL" core.editor)" = "nvim" ]
}

@test "skips the identity prompt entirely when name and email are already configured" {
  git config --file "$_GITCONFIG_LOCAL" user.name "Existing User"
  git config --file "$_GITCONFIG_LOCAL" user.email "existing@example.com"
  run setup_git <<< $'5\n'
  [[ "$output" == *"already configured"* ]]
  [ "$(git config --file "$_GITCONFIG_LOCAL" user.name)" = "Existing User" ]
}

@test "fails after 3 empty attempts at the name prompt" {
  run setup_git <<< $'\n\n\n'
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot be empty"* ]]
}

@test "fails after 3 empty attempts at the email prompt once name is given" {
  run setup_git <<< $'Jane Doe\n\n\n\n'
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot be empty"* ]]
  [ "$(git config --file "$_GITCONFIG_LOCAL" user.name)" = "Jane Doe" ]
}

@test "editor choice 5 leaves core.editor unset (system default)" {
  run setup_git <<< $'Jane Doe\njane@example.com\n5\n'
  run git config --file "$_GITCONFIG_LOCAL" core.editor
  [ "$status" -ne 0 ]
  [ -z "$output" ]
}

@test "editor choice 3 maps to vim" {
  run setup_git <<< $'Jane Doe\njane@example.com\n3\n'
  [ "$(git config --file "$_GITCONFIG_LOCAL" core.editor)" = "vim" ]
}

@test "editor choice 4 maps to nano" {
  run setup_git <<< $'Jane Doe\njane@example.com\n4\n'
  [ "$(git config --file "$_GITCONFIG_LOCAL" core.editor)" = "nano" ]
}

@test "an unrecognized editor choice defaults to VS Code" {
  run setup_git <<< $'Jane Doe\njane@example.com\n9\n'
  [ "$(git config --file "$_GITCONFIG_LOCAL" core.editor)" = "code --wait" ]
}

@test "re-running with an already-configured editor skips the editor prompt" {
  git config --file "$_GITCONFIG_LOCAL" user.name "Jane Doe"
  git config --file "$_GITCONFIG_LOCAL" user.email "jane@example.com"
  git config --file "$_GITCONFIG_LOCAL" core.editor "vim"
  run setup_git
  [[ "$output" == *"already configured"* ]]
  [ "$(git config --file "$_GITCONFIG_LOCAL" core.editor)" = "vim" ]
}
