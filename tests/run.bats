#!/usr/bin/env bats
# Unit tests for run.sh: _run_selection() (the menu-selection parser), the OS-exclusive
# menu filtering in _run_interactive(), and the direct function-dispatch path.
# Includes regression coverage for the bug where an out-of-range plain number
# (e.g. "3,999") would run earlier valid selections before the invalid token was
# ever reported.

setup() {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../run.sh"

  _names=()
  _names[1]="fn_one"
  _names[2]="fn_two"
  _names[3]="fn_three"
  fn_one()   { echo "ran-fn_one"; }
  fn_two()   { echo "ran-fn_two"; }
  fn_three() { echo "ran-fn_three"; }
}

@test "single valid selection runs the matching function" {
  run _run_selection "2"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ran-fn_two"* ]]
}

@test "comma-separated list runs every selection" {
  run _run_selection "1,3"
  [[ "$output" == *"ran-fn_one"* ]]
  [[ "$output" == *"ran-fn_three"* ]]
  [[ "$output" != *"ran-fn_two"* ]]
}

@test "range expands and runs every function in it" {
  run _run_selection "1-3"
  [[ "$output" == *"ran-fn_one"* ]]
  [[ "$output" == *"ran-fn_two"* ]]
  [[ "$output" == *"ran-fn_three"* ]]
}

@test "out-of-range number in a range is rejected before anything runs" {
  run _run_selection "1-999"
  [[ "$output" != *"ran-fn_one"* ]]
  [[ "$output" == *"Invalid selection"* ]]
}

@test "out-of-range plain number rejects the whole selection, not just itself" {
  # this is the exact bug found in review: "3,999" used to run fn_three
  # before discovering 999 was invalid
  run _run_selection "3,999"
  [[ "$output" != *"ran-fn_three"* ]]
  [[ "$output" == *"Invalid selection"* ]]
}

@test "malformed token rejects the whole selection" {
  run _run_selection "1,abc"
  [[ "$output" != *"ran-fn_one"* ]]
  [[ "$output" == *"Invalid selection"* ]]
}

@test "empty input is rejected" {
  run _run_selection ""
  [[ "$output" == *"Invalid selection"* ]]
}

@test "spaces and commas can be mixed in the same selection" {
  run _run_selection "1, 2 3"
  [[ "$output" == *"ran-fn_one"* ]]
  [[ "$output" == *"ran-fn_two"* ]]
  [[ "$output" == *"ran-fn_three"* ]]
}

@test "multiple ranges in one selection all expand and run" {
  run _run_selection "1-1,3-3"
  [[ "$output" == *"ran-fn_one"* ]]
  [[ "$output" == *"ran-fn_three"* ]]
  [[ "$output" != *"ran-fn_two"* ]]
}

@test "a reversed range (start greater than end) is rejected" {
  run _run_selection "3-1"
  [[ "$output" != *"ran-fn_"* ]]
  [[ "$output" == *"Invalid selection"* ]]
}

@test "a bare dash with no numbers is rejected" {
  run _run_selection "-"
  [[ "$output" == *"Invalid selection"* ]]
}

@test "duplicate selections run their function once per occurrence, not deduped" {
  # functions are idempotent by design (see run.sh's own comment on _run_selection),
  # so re-running the same one twice is expected behavior, not a bug
  run _run_selection "1,1"
  local _count
  _count="$(grep -c "ran-fn_one" <<< "$output")"
  [ "$_count" -eq 2 ]
}

# -- _run_interactive() OS-exclusive menu filtering --
# setup_homebrew/setup_apt are the only two menu entries gated to one OS - feeding
# "q" immediately avoids blocking on the rest of the interactive prompt

@test "menu shows setup_homebrew and hides setup_apt when OS=macos" {
  OS="macos"
  run _run_interactive <<< "q"
  [[ "$output" == *"setup_homebrew"* ]]
  [[ "$output" != *"setup_apt"* ]]
}

@test "menu shows setup_apt and hides setup_homebrew when OS is not macos" {
  OS="ubuntu"
  run _run_interactive <<< "q"
  [[ "$output" == *"setup_apt"* ]]
  [[ "$output" != *"setup_homebrew"* ]]
}

# -- Direct dispatch (bash run.sh <function>) --
# executed as a real subprocess, not sourced, since this is exactly what a user
# invoking `bash run.sh setup_x` actually does

@test "running run.sh directly with an unknown function name exits 1" {
  run bash "${BATS_TEST_DIRNAME}/../run.sh" this_function_does_not_exist
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown function"* ]]
}

@test "running run.sh directly with a known function name invokes it" {
  # dispatches to detect_os specifically because it's side-effect-free - any real
  # setup_* function would risk triggering an actual package-manager install on a
  # machine that doesn't already have that tool (e.g. a fresh CI runner)
  run bash "${BATS_TEST_DIRNAME}/../run.sh" detect_os
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^(macos|ubuntu|debian|linux|unknown)$ ]]
}
