# ~/.zshrc — interactive shells.

# Homebrew (non-login shells miss .zprofile)
[ -n "${HOMEBREW_PREFIX:-}" ] || { [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"; }

# mise: every runtime + global tool (~/.config/mise/config.toml)
command -v mise >/dev/null && eval "$(mise activate zsh)"

# prompt — robbyrussell, no oh-my-zsh
autoload -Uz vcs_info compinit add-zsh-hook && compinit -C
zstyle ':vcs_info:git:*' formats ' %F{blue}git:(%F{red}%b%F{blue})%f'
add-zsh-hook precmd vcs_info
setopt PROMPT_SUBST
PROMPT='%(?.%F{green}.%F{red})➜%f  %F{cyan}%c%f${vcs_info_msg_0_} '

# history
HISTFILE=~/.zsh_history HISTSIZE=100000 SAVEHIST=100000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# brew zsh plugins
for f in zsh-autosuggestions/zsh-autosuggestions.zsh zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [ -r "${HOMEBREW_PREFIX:-/opt/homebrew}/share/$f" ] && source "${HOMEBREW_PREFIX:-/opt/homebrew}/share/$f"
done

export CLICOLOR=1
alias ls='ls -G'
alias ic='cd ~/Library/Mobile\ Documents/com~apple~CloudDocs'
alias update-claude='mise upgrade npm:@anthropic-ai/claude-code'
alias cfg='git --git-dir=$HOME/.cfg --work-tree=$HOME'   # this repo, checked out over $HOME

# Claude Code profiles (CLAUDE_CONFIG_DIR switcher)
source ~/.config/claude-profile/claude-profile.zsh
# Pin the default profile at shell init: cmux exec's the claude binary directly,
# bypassing the claude() wrapper. An already-set value wins.
if [ -z "${CLAUDE_CONFIG_DIR:-}" ] && [ -r "$HOME/.claude-profiles/.default" ]; then
  _cp_def=$(cat "$HOME/.claude-profiles/.default" 2>/dev/null)
  [ -n "$_cp_def" ] && [ -d "$HOME/.claude-profiles/$_cp_def" ] \
    && export CLAUDE_CONFIG_DIR="$HOME/.claude-profiles/$_cp_def"
  unset _cp_def
fi

# machine-local + secrets. never tracked.
[ -r ~/.zshrc.local ] && source ~/.zshrc.local
