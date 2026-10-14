# dotfiles

`$HOME` is the repo. A bare git repo at `~/.cfg` has `$HOME` as its worktree, so tracked files live in place: no symlinks, no copying, no sync script. `cfg status` shows drift. `cfg add -u` stages it.

Packages, runtimes and tools are declared, not scripted: `~/.Brewfile` (Homebrew), `~/.config/mise/config.toml` (mise). A short Makefile converges the machine.

This repo is public and holds only tools and generic config. Everything else is its own repo, cloned by the Makefile:

| repo | visibility | lands at | target |
|---|---|---|---|
| [sajarin/claude-profiles](https://github.com/sajarin/claude-profiles) | private | `~/.claude-profiles` | `make private` |
| [sajarin/vim-config](https://github.com/sajarin/vim-config) | public | `~/Desktop/Code/vim-config`, `~/.vimrc` symlinks into it | `make vim` |
| [shihabdider/autocode](https://github.com/shihabdider/autocode) | private | `~/Desktop/Code/autocode`, `bun link`ed CLI, `/autocode` skill + SessionStart hook in every profile | `make autocode` |
| [sajarin/zealot](https://github.com/sajarin/zealot) | private | `~/Desktop/Code/zealot`, binary in `~/.local/bin` | `make zealot` |

## Fresh machine

```sh
xcode-select --install                                   # 1. git, make, clang. Wait for the dialog to finish.
git clone --bare https://github.com/sajarin/dotfiles ~/.cfg       # 2.
git --git-dir=$HOME/.cfg --work-tree=$HOME checkout               # 3. tracked files land in place
git --git-dir=$HOME/.cfg config status.showUntrackedFiles no      #    so `cfg status` ignores the rest of $HOME
git --git-dir=$HOME/.cfg config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git --git-dir=$HOME/.cfg fetch && git --git-dir=$HOME/.cfg branch -u origin/main main   #    bare clones have no upstream; cfg pull/push need one
make -C ~/.config/bootstrap brew                         # 4. Homebrew (sudo password once) + Brewfile
gh auth login && gh auth setup-git                       # 5. private repos, and git push over https
make -C ~/.config/bootstrap all                          # 6. mise, vim-config, claude-profiles, plugins, autocode, zealot
exec zsh                                                 # 7. new shell: PATH, mise, aliases, profile env
```

Why this order:

- Step 3 is a plain checkout because a fresh account has nothing that collides. If it refuses, move the named file aside and re-run. Without `showUntrackedFiles no`, every file in `$HOME` shows up as untracked and `make doctor` reports drift.
- Step 4 before 5 because `gh` comes from the Brewfile.
- Step 5 before 6 because `make private`, `make autocode` and `make zealot` clone private repos. All three check `gh auth status` and say so if you skipped this. `setup-git` routes every https push and pull through the gh token, so an SSH key is optional.
- Step 6 is long. mise builds the cargo tools from source and zealot compiles in release mode. 15 to 25 minutes.
- Step 7 because `make` ran under the stock shell; nothing in the rc files was loaded yet.

`curl -fsSL https://raw.githubusercontent.com/sajarin/dotfiles/main/.local/bin/bootstrap | bash` does steps 1 to 3 and then `make all`; run step 5 before it, or `make private claude autocode zealot` afterwards.

Then the manual bits. `make doctor` lists whichever are still missing:

- `cp ~/.zshrc.local.example ~/.zshrc.local`, fill in `ZEALOT_PYLON_TOKEN` (or comment it out until you have one)
- `claude` once per profile to log in (`claude-profile use work; claude`)
- zealot: `user_id` in `~/Library/Application Support/zealot/config.toml`
- MCP servers: after logging in, `claude mcp add` them per profile (blender in both, zapier in work), then authenticate in `/mcp`
- optional: `ssh-keygen -t ed25519 && gh ssh-key add ~/.ssh/id_ed25519.pub`
- 1Password, Raycast, cmux, Ghostty: open once, sign in, grant permissions

## Existing machine

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/sajarin/dotfiles/main/.local/bin/bootstrap) help
```

Checks out the repo over `$HOME` and stops (`help` is a no-op target). Files that would be overwritten are moved to `~/.cfg-backup/<timestamp>/`, never deleted. Then `make all` at your own pace. Two targets move untracked things into that same backup dir before replacing them: `make private` (an unmanaged `~/.claude-profiles`; quit running Claude Code sessions first) and `make vim` (a plain-file `~/.vimrc`).

## Daily

| command | does |
|---|---|
| `bootstrap [target]` | `cfg pull`, then `make -C ~/.config/bootstrap <target>` (default `all`) |
| `make doctor` | non-zero if Brewfile, mise, vimrc link, or either repo has drifted; prints manual todos |
| `make sync` | scrubs secrets that leaked into profile `permissions.allow`, stages both repos |
| `cfg commit -m ... && cfg push` | publish dotfiles. `git -C ~/.claude-profiles commit && push` for the private one |
| `make brew-extra` | opt-in heavy stuff: Postgres, Blender, Android, game/graphics libs |
| `make help` | targets |

Adding something: a package is one line in `.Brewfile`; a runtime or global CLI is one line in `.config/mise/config.toml`; a new dotfile is `cfg add -f <path>`; anything Claude-related goes in claude-profiles; anything vim goes in vim-config.

## Layout

```
.Brewfile  .Brewfile.extra            packages
.config/mise/config.toml              node, bun, go, rust, python, java + npm/go/pipx/cargo tools
.config/bootstrap/Makefile            all brew brew-extra mise vim private claude autocode zealot doctor sync help
.config/bootstrap/claude-plugins.txt  marketplaces + plugins installed into every profile
.config/claude-profile/               claude-profile.zsh: CLAUDE_CONFIG_DIR switcher (generic, no personal data)
.config/{ghostty,cmux}/               terminal
.config/nvim/                         init.lua + lazy-lock.json
.gitconfig  .config/git/ignore        identity, global ignores
.zshenv .zprofile .zshrc              PATH · Homebrew · prompt, mise, aliases, profiles. No oh-my-zsh.
.zshrc.local.example                  template; real ~/.zshrc.local is gitignored
.local/bin/bootstrap                  installer + updater (the curl target)
```

## Secrets

Never tracked anywhere: `~/.zshrc.local`, `~/.ssh`, `*/.claude.json`, `~/.config/gh`. `make doctor` fails if a `KEY=value` entry appears in any profile's `permissions.allow`. That happens when "always allow" is chosen on a Bash command that inlines an env var; `make sync` strips them.

## Not carried over from the old machine

- oh-my-zsh, nvm, pyenv, pipx, rustup, `npm -g` — replaced by mise and a 43-line `.zshrc`
- tmux + TPM + workmode — cmux does this now
- job-specific Homebrew taps, Go tools, work repos
- `dd-cli` binary — work tool, no source repo. (`autocode` comes back through `make autocode`.)
- Solana toolchain, gcloud from `~/Downloads` — gcloud is a cask now, Solana goes in `.zshrc.local` if needed
- one-off scripts (`find-available-port`, `icloud-nosync-watch`) and the hand-written `.vimrc` — vim config comes from vim-config now
