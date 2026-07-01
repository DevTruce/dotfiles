#!/usr/bin/env bats
# Unit tests for scripts/version-control.sh: setup_git()'s identity-prompt and
# editor-selection logic, and setup_git_lfs()'s hook-registration check. Safe to
# run for real because `command -v git` is assumed to succeed (true on any dev/CI
# box) and setup_git_lfs gets a fake git-lfs on PATH, so neither "install X" branch
# ever triggers - only the prompt/config/hook logic below them is exercised,
# against a fixture $HOME so the real ~/.gitconfig.local is never touched.

setup() {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../scripts/helpers.sh"
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../scripts/version-control.sh"

  _FAKE_HOME="$(mktemp -d)"
  HOME="$_FAKE_HOME"
  _GITCONFIG_LOCAL="${_FAKE_HOME}/.gitconfig.local"

  _FAKE_BIN="$(mktemp -d)"
  export PATH="${_FAKE_BIN}:${PATH}"
}

teardown() {
  rm -rf "$_FAKE_HOME" "$_FAKE_BIN"
}

# stands in for the real git-lfs binary: `git lfs install` dispatches to whatever
# `git-lfs` executable is on PATH, so this intercepts it and mimics just enough of
# its real behavior (writing a pre-push hook into the configured hooksPath) for
# setup_git_lfs's own hook-registration check to be testable without a real install
_fake_git_lfs() {
  cat > "${_FAKE_BIN}/git-lfs" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "install" ]; then
  _hooks_dir="$(git config core.hooksPath)"
  mkdir -p "$_hooks_dir"
  touch "${_hooks_dir}/pre-push"
fi
exit 0
EOF
  chmod +x "${_FAKE_BIN}/git-lfs"
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

# -- setup_git_lfs() --

@test "registers hooks and points core.hooksPath at them on a fresh setup" {
  _fake_git_lfs
  run setup_git_lfs
  [ "$status" -eq 0 ]
  [ -f "${_FAKE_HOME}/.config/git/hooks/pre-push" ]
  [ "$(git config --file "$_GITCONFIG_LOCAL" core.hooksPath)" = "${_FAKE_HOME}/.config/git/hooks" ]
}

@test "skips re-registering when the hook file exists and core.hooksPath already matches" {
  _fake_git_lfs
  setup_git_lfs >/dev/null
  run setup_git_lfs
  [[ "$output" == *"already registered"* ]]
}

@test "re-registers when core.hooksPath is set but the hook file is missing" {
  _fake_git_lfs
  mkdir -p "${_FAKE_HOME}/.config/git/hooks"
  git config --file "$_GITCONFIG_LOCAL" core.hooksPath "${_FAKE_HOME}/.config/git/hooks"
  run setup_git_lfs
  [[ "$output" != *"already registered"* ]]
  [ -f "${_FAKE_HOME}/.config/git/hooks/pre-push" ]
}

@test "re-registers when the hook file exists but core.hooksPath points elsewhere" {
  _fake_git_lfs
  mkdir -p "${_FAKE_HOME}/.config/git/hooks"
  touch "${_FAKE_HOME}/.config/git/hooks/pre-push"
  git config --file "$_GITCONFIG_LOCAL" core.hooksPath "/some/other/path"
  run setup_git_lfs
  [[ "$output" != *"already registered"* ]]
  [ "$(git config --file "$_GITCONFIG_LOCAL" core.hooksPath)" = "${_FAKE_HOME}/.config/git/hooks" ]
}
