# Disable macOS Terminal.app's session save/restore (see /etc/zshrc_Apple_Terminal).
# On session restore (quit-and-reopen, "Reopen windows", crash recovery) it sources
# a leftover `echo Restored session: ...` command from ~/.zsh_sessions before
# ~/.zshrc even runs, which shows up as a duplicate-looking prompt on new terminals.
export SHELL_SESSIONS_DISABLE=1
