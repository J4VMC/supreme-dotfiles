# AGENTS.md — dotfiles

Instructions for AI coding agents working in this repository, or installing it on a Mac. The [README](README.md) explains the reasoning behind every rule here; this file is the executable version. When the two disagree, the README wins and this file has a bug.

## What this repository is

A GNU Stow–managed set of macOS dotfiles. Each top-level directory is a stow package whose contents mirror `$HOME`. Two packages are git submodules with their own repositories, histories and `AGENTS.md`:

- `emacs/` → [J4VMC/supreme-emacs](https://github.com/J4VMC/supreme-emacs), linked to `~/.config/emacs`
- `fish/` → [J4VMC/supreme-fish](https://github.com/J4VMC/supreme-fish), linked to `~/.config/fish`

The repository is **public**. Nothing client-specific, no credentials, no machine-local state goes into it.

## Hard rules

1. **Never run `lefthook install`** here or in any other repository on the machine. `~/.gitconfig` sets a global `core.hooksPath`; the global hooks already dispatch to `lefthook run` when a `lefthook.yml` exists. `lefthook install --force` would overwrite the global hooks for every repository.
2. **Never commit a credential.** `npm/.npmrc` is stowed to `~/.npmrc`, where `npm login` writes tokens; the pre-commit hook rejects credential-looking lines there, but do not rely on it. Reference secrets from the environment (`${NPM_TOKEN}`).
3. **Never add `npm "..."` lines to `homebrew/.Brewfile`.** npm globals live in `npm/.npm-globals` only. `maintain` sets `HOMEBREW_BUNDLE_DUMP_NO_NPM` for this reason.
4. **Never add client names, work identities or private hostnames** to any tracked file. They belong in `~/.gitconfig.local`, `~/.config/chrome-router/`, per-project `.envrc` files, or the gitignored helpers listed in the README's "What is deliberately not tracked".
5. **Never edit the generated fish snapshots by hand** (`fish/.config/fish/conf.d/*_init.fish`, `direnv_hook.fish` below its header). Run `regen-shell-inits`.
6. **Commit messages follow Conventional Commits.** `lefthook.yml` runs `cog verify` on every commit in all three repositories. Scope by package when it helps: `docs(readme):`, `fix(ghostty):`, `chore(fish): bump pointer ...`.
7. **Submodules: push first, point second, and only at commits on the submodule's `main`.** See [Changing a submodule](#changing-a-submodule).
8. **Do not add AI attribution trailers** to commits. The global `commit-msg` hook strips them anyway.

## Installing on a fresh Mac

Run the steps in this order. Each has a check; do not continue past a failed check. Steps marked **HUMAN** need the person: a password, a browser login, a macOS permission dialog, or a decision. Stop and ask at those points rather than working around them.

Steps 1–6 run in the zsh a fresh Mac starts with. From step 7 the commands are fish syntax.

### 1. Homebrew

```bash
command -v brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**HUMAN**: the installer asks for the login password and installs the Xcode Command Line Tools. Check: `brew --version` prints a version. On Apple silicon `brew --prefix` is `/opt/homebrew`; on Intel `/usr/local`. Everything downstream derives paths from that, so do not hardcode either.

### 2. Clone with submodules

```bash
git clone --recurse-submodules git@github.com:J4VMC/supreme-dotfiles.git ~/dotfiles
```

If the machine has no SSH key with access to GitHub (`ssh -T git@github.com` fails), use HTTPS for everything instead:

```bash
git config --global url."https://github.com/".insteadOf git@github.com:
git clone --recurse-submodules https://github.com/J4VMC/supreme-dotfiles.git ~/dotfiles
```

Check: `ls ~/dotfiles/fish/.config/fish/config.fish` and `ls ~/dotfiles/emacs/.config/emacs/init.el` both exist. An uninitialised submodule is an **empty directory**, and `stow` would silently link nothing from it; if either file is missing run `git -C ~/dotfiles submodule update --init` before continuing.

### 3. Stow, in this exact order

```bash
brew install stow
cd ~/dotfiles
stow stow
stow emacs emacs-plus fish git ghostty starship fastfetch homebrew npm bin zsh
stow --no-folding herdr
```

Rules that are easy to break here:

- `stow stow` **first and for real**, never `-n`. It links `~/.stow-global-ignore`, which Stow only honours once that link exists. Running anything else before it (or `stow */`, or a dry run) produces conflicts on `lefthook.yml` and `.DS_Store` or links those into `~`. Recovery: `stow -D <package>` for each affected package, then redo in order.
- `stow fish` **before any fish shell has ever started** on the machine. Fish's first start creates a real `~/.config/fish/`, and Stow then links file by file instead of folding. If `~/.config/fish` already exists and is not a symlink: move `fish_variables` and `plugins/` aside, `stow -D fish`, `rmdir ~/.config/fish`, `stow fish`, move them back.
- `herdr` only with `--no-folding`; a folded link would put herdr's runtime state inside the repository.
- `stow npm` refuses if a real `~/.npmrc` exists. Check it holds no token, then delete it (or `stow --adopt npm` and review `git diff`).

Check: `readlink ~/.config/fish ~/.config/emacs ~/.Brewfile ~/.npm-globals ~/.gitconfig ~/.zshenv ~/.config/herdr/config.toml` all resolve into `~/dotfiles`, and `readlink ~/.config/herdr` prints nothing (it is a real directory).

### 4. Git identity (HUMAN)

The stowed `~/.gitconfig` sets `user.useConfigOnly`, so **every commit fails** until `~/.gitconfig.local` exists. Ask the person for the name and email to use, then:

```bash
printf '[user]\n    name = %s\n    email = %s\n' "Their Name" "their@email" > ~/.gitconfig.local
```

Commits are SSH-signed with `~/.ssh/id_ed25519.pub`. If the key has a different name, add `signingkey = ~/.ssh/<name>.pub` under `[user]` in the same file. Check: `git -C ~/dotfiles config user.name` prints the name, and `ssh-keygen -l -f "$(git config user.signingkey)"` prints a fingerprint.

### 5. Homebrew bundle

```bash
brew bundle --global
```

This is long (it builds Emacs from source). Third-party formulae are pre-trusted by the `trusted:` annotations in the Brewfile; if Homebrew still refuses one with "untrusted tap", run `brew trust <tap>` and retry rather than editing the Brewfile. Check: `brew bundle check --global` reports everything installed, and `emacs --version` reports 31.x.

Afterwards, copy the Emacs apps so they appear in `/Applications` (the formula does not):

```bash
cp -R /opt/homebrew/opt/emacs-plus@31/Emacs.app "/opt/homebrew/opt/emacs-plus@31/Emacs Client.app" /Applications/
```

Use `/usr/local/opt/...` on Intel.

### 6. Login shell (HUMAN)

```bash
echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells && chsh -s "$(brew --prefix)/bin/fish"
```

Both commands prompt for the password. Check: `dscl . -read ~ UserShell` ends in `/bin/fish`. Open a new terminal (or run `fish`) before the next step; the remaining commands are fish syntax.

### 7. Node and npm globals

```fish
nvm install lts; and set -U nvm_default_version (node --version); and npm-globals install
```

`nvm_default_version` must be a concrete `vX.Y.Z`, never `lts`; the command above guarantees that. Check: `fish -c 'command -v node'` points under `~/.local/share/nvm/`, not under the Homebrew prefix, and `fish -c 'command -v typescript-language-server'` resolves.

### 8. docker compose plugin path

```fish
jq --arg d "$(brew --prefix)/lib/docker/cli-plugins" '.cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$d] | unique)' ~/.docker/config.json > ~/.docker/config.json.new; and mv ~/.docker/config.json.new ~/.docker/config.json
```

If `~/.docker/config.json` does not exist yet, create it as `{}` first. Check: `docker compose version` works (start `colima` first if the daemon is needed).

### 9. Karabiner-Elements (HUMAN)

```fish
brew install --cask karabiner-elements
```

If `/Applications/Karabiner-Elements.app` already exists from a website download, the cask fails; that is fine, skip the install. Then the person must, in System Settings → Privacy & Security, allow the Karabiner driver extension and grant Input Monitoring to `karabiner_grabber` and `karabiner_observer`, and in Karabiner-Elements → Complex Modifications add the predefined rule *"Change caps_lock to control if pressed with other keys, to escape if pressed alone"*. None of that can be scripted; do not try to edit `~/.config/karabiner/karabiner.json` directly while the app is running.

### 10. Per-machine extras

- `herdr integration install claude` — once, so herdr sees Claude Code sessions.
- Ghostty's global quick terminal (`⌘` + `` ` ``) needs the Accessibility permission (**HUMAN**).
- `~/.config/chrome-router/<context>.conf` rules for `chrome-route` are untracked; restore from the previous machine if there was one (**HUMAN** decision).
- `~/.ssh/allowed_signers` is only needed to verify commit signatures locally.

### 11. Final verification

```fish
fish -c 'echo $HOMEBREW_PREFIX; command -v starship direnv zoxide pyenv eza bat' # all resolve
git -C ~/dotfiles status --short                                                 # clean
git -C ~/dotfiles submodule status                                               # no + or - prefix
emacs --version                                                                  # 31.x
```

Do not launch Emacs non-interactively to "test" the configuration: the first launch installs every package through Elpaca (minutes), compiles jinx's native module, and asks before installing tree-sitter grammars. Let the person do that first launch from `/Applications/Emacs.app` and report back.

## Maintenance

- `maintain` is the single maintenance entry point (Homebrew, fisher weekly, Brewfile dump, npm globals dump, snapshot regen). After it runs, `git -C ~/dotfiles status` typically shows `homebrew/.Brewfile`, `npm/.npm-globals` and the fish `conf.d` snapshots modified. Review the diff; commit with `chore(brew): ...`, `chore(npm): ...` or `chore(fish): ...`.
- `brew bundle dump` output for a formula that was uninstalled simply disappears from the Brewfile. That is the intended way to remove packages: uninstall, then `brewed`.
- Do not add `cask "karabiner-elements"` even if the app is installed; see step 9 for why.

## Changing a submodule

`git pull` in the parent moves both submodule checkouts (`submodule.recurse` is on) and leaves them detached. Before committing inside one:

```fish
cd ~/dotfiles/fish          # or emacs
git checkout main
git pull --ff-only
# edit, commit (Conventional Commits)
git push origin main
cd ~/dotfiles
git add fish
git commit -m "chore(fish): bump pointer to <what changed>"
git push origin main
```

The parent push is refused by git if the submodule commit is not on its remote yet; that is correct, push the submodule. Never record a pointer to a commit on a pull-request branch that may be rebased or squashed: the recorded hash becomes unreachable and every fresh clone fails in `git submodule update`.

## Where things are documented

| Topic | File |
| ----- | ---- |
| Why each install rule exists, component overview, untracked files | `README.md` |
| Fish startup order, functions, plugins, snapshots | `fish/README.md`, `fish/AGENTS.md` |
| Emacs install guide and every keybinding | `emacs/.config/emacs/README.md`, `emacs/AGENTS.md` |
| Global git hooks and the lefthook hand-off | `git/.config/git/hooks/lefthook-dispatch` (header comment) |
| Stow ignore semantics | `stow/.stow-global-ignore` (header comment) |
| direnv in non-interactive zsh | `zsh/.zshenv` (header comment) |
| Chrome profile router | `bin/bin/chrome-route` (header comment) |

Configuration files in this repository carry long header comments on purpose; read them before changing behaviour, and keep them accurate when you do.
