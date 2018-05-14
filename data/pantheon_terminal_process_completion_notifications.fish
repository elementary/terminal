# This file provides notifications about command completion to Pantheon Terminal,
# which displays desktop notifications and/or tab icons, if appropriate.

function pantheon-terminal-process-completion-callback --on-event fish_postexec --description "Notify Pantheon Terminal about task completion"
    set cmd_exit_status $status
    if status --is-interactive; and set --query PANTHEON_TERMINAL_ID
        dbus-send --type=method_call --session --dest=io.elementary.terminal /io/elementary/terminal io.elementary.terminal.ProcessFinished string:$PANTHEON_TERMINAL_ID string:"$argv[1]" int32:$cmd_exit_status;
    end
end

# Some shells (e.g. BASH) lack the post-execution hook,
# so we insert a callback into their pre-prompt hook instead.
# This results in a bogus callback on first prompt, which has to be ignored.
# We've tried some clever focus-based suppression but it was prone to race conditions.
# The only reliable way to work that around that we've found
# is always ignoring the first callback in each tab on the terminal side
# and deliberately issuing a fake callback from shells with a proper
# post-execution hook, such zsh and fish.
if status --is-interactive; and set --query PANTHEON_TERMINAL_ID
    pantheon-terminal-process-completion-callback "You should not have seen this, please report the incident to Pantheon Terminal developers."
end
