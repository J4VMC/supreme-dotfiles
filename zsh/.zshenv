# =============================================================================
# .zshenv --- load the current directory's .envrc in non-interactive zsh
# =============================================================================
#
# Commentary:
# fish is the login shell, and direnv reaches it through the prompt hook in
# fish/.config/fish/conf.d/direnv_hook.fish. zsh only runs here without a
# prompt: the Claude desktop app executes every Bash-tool command as
# `/bin/zsh -c ...` (fish is not a supported tool shell), and a prompt hook
# never fires in a shell that shows no prompt. So a Claude session inside a
# client tree used to run with none of that tree's .envrc: gh answered as
# the personal account because GH_CONFIG_DIR was unset (404s and "Could not
# resolve to a Repository" on client repos) and AWS_PROFILE was unset. (Git
# identity was fine: ~/.gitconfig.local routes it by directory, not by
# environment.)
#
# .zshenv is the one startup file every zsh reads, interactive or not, so
# this evaluates the nearest .envrc exactly once, at startup, for the
# directory the shell was started in -- the same thing the fish hook does
# at each prompt. Every tool command is a fresh zsh started in the
# session's working directory, so the environment always matches that
# directory: ~50ms when an .envrc applies, nothing measurable when none
# does. direnv's own trust model still applies: only an .envrc that was
# `direnv allow`ed loads, anything else exports nothing.
#
# direnv normally prints "loading ..." and "export +A +B" on stderr. That
# would prefix the output of every command, so stderr is dropped on the
# happy path and, when direnv fails (blocked .envrc, error inside it), the
# export is run a second time only to let its message through. (Setting
# DIRENV_LOG_FORMAT to the empty string is the documented way to silence
# the status lines, but direnv 2.37 only reads that variable when a
# ~/.config/direnv/direnv.toml exists, and this must not depend on that.)
#
# An interactive zsh -- not the login shell on this machine -- would want
# `eval "$(direnv hook zsh)"` in a .zshrc as well; this file still gives
# it the environment of the directory it started in.
#
# Nothing client-specific lives here: the .envrc files do the routing.
# =============================================================================

for _direnv in "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin/direnv}" \
               /opt/homebrew/bin/direnv /usr/local/bin/direnv; do
    [[ -n $_direnv && -x $_direnv ]] || continue
    if _direnv_env=$("$_direnv" export zsh 2>/dev/null); then
        eval "$_direnv_env"
    else
        # Failed: run it again purely for its error message.
        "$_direnv" export zsh >/dev/null
    fi
    break
done
unset _direnv _direnv_env
