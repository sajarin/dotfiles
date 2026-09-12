# ~/.config/bootstrap/Makefile — converge this machine on the tracked state.
# `bootstrap [target]` pulls then runs this. Every target is idempotent.
SHELL := /bin/bash
export PATH := $(HOME)/.local/bin:$(HOME)/.local/share/mise/shims:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$(PATH)
export NONINTERACTIVE := 1

CFG      := git --git-dir=$(HOME)/.cfg --work-tree=$(HOME)
CODE     := $(HOME)/Desktop/Code
PROFILES := $(HOME)/.claude-profiles
PRIVATE  := sajarin/claude-profiles
VIMCONF  := $(CODE)/vim-config
ZEALOT   := $(CODE)/zealot
BACKUP   := $(HOME)/.cfg-backup/$(shell date +%Y%m%d%H%M%S)
SECRETS  := [.permissions.allow[]? | select(test("[A-Z_]{3,}="))] | length > 0

.PHONY: all brew brew-extra mise vim private claude zealot doctor sync help
.DEFAULT_GOAL := help

all: brew mise vim private claude zealot ## converge everything

brew: ## Homebrew + ~/.Brewfile
	@command -v brew >/dev/null || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew bundle --file=$(HOME)/.Brewfile --no-upgrade

brew-extra: brew ## ~/.Brewfile.extra (databases, game deps, big casks)
	brew bundle --file=$(HOME)/.Brewfile.extra --no-upgrade

mise: brew ## runtimes + global tools (~/.config/mise/config.toml)
	mise install --yes

vim: ## sajarin/vim-config → ~/.vimrc (symlink); vim-plug + plugins
	@[ -d $(VIMCONF) ] || git clone --quiet https://github.com/sajarin/vim-config $(VIMCONF)
	git -C $(VIMCONF) pull --quiet --ff-only
	@if [ -e $(HOME)/.vimrc ] && [ ! -L $(HOME)/.vimrc ]; then \
	    echo "moving untracked ~/.vimrc → $(BACKUP)/"; mkdir -p $(BACKUP); mv $(HOME)/.vimrc $(BACKUP)/.vimrc; fi
	ln -sfn $(VIMCONF)/.vimrc $(HOME)/.vimrc
	@[ -f $(HOME)/.vim/autoload/plug.vim ] || curl -fsSLo $(HOME)/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	vim -es -u $(HOME)/.vimrc -i NONE -c 'PlugInstall --sync' -c 'qa!'

private: brew ## sajarin/claude-profiles → ~/.claude-profiles (needs gh auth login)
	@gh auth status >/dev/null 2>&1 || { echo "run 'gh auth login' first"; exit 1; }
	@if [ -d $(PROFILES) ] && [ ! -d $(PROFILES)/.git ]; then \
	    echo "moving untracked $(PROFILES) → $(BACKUP)/"; mkdir -p $(BACKUP); mv $(PROFILES) $(BACKUP)/.claude-profiles; fi
	@[ -d $(PROFILES)/.git ] || gh repo clone $(PRIVATE) $(PROFILES)
	git -C $(PROFILES) pull --quiet --ff-only

claude: private mise ## plugins into every profile; gmail skill deps
	@for p in $(PROFILES)/*/; do \
	    echo "== $$p"; \
	    while read -r kind arg; do \
	        [ -n "$$kind" ] && CLAUDE_CONFIG_DIR=$$p claude plugin $$kind $$arg </dev/null || true; \
	    done < $(HOME)/.config/bootstrap/claude-plugins.txt; \
	done
	@cd $(PROFILES)/.shared/skills/gmail && bun install --silent

zealot: mise ## sajarin/zealot: build from source, install binary, sound pack, config
	@gh auth status >/dev/null 2>&1 || { echo "zealot is a private repo: run 'gh auth login' first"; exit 1; }
	@[ -d $(ZEALOT) ] || gh repo clone sajarin/zealot $(ZEALOT)
	cd $(ZEALOT) && cargo build --release
	install -m 755 $(ZEALOT)/target/release/zealot $(HOME)/.local/bin/zealot
	@[ -d $(HOME)/.config/zealot/sounds/protoss ] || $(ZEALOT)/scripts/download-protoss-pack.sh
	@d="$(HOME)/Library/Application Support/zealot"; mkdir -p "$$d"; \
	    [ -f "$$d/config.toml" ] || cp $(ZEALOT)/config.example.toml "$$d/config.toml"

doctor: ## converged? non-zero on drift; prints manual todos
	@ok=1; \
	brew bundle check --file=$(HOME)/.Brewfile --no-upgrade >/dev/null || { echo "✗ brew: missing packages → make brew"; ok=0; }; \
	m="$$(mise ls --missing 2>/dev/null)"; [ -z "$$m" ] || { echo "✗ mise: missing tools → make mise"; echo "$$m"; ok=0; }; \
	[ -L $(HOME)/.vimrc ] || { echo "✗ vim: ~/.vimrc is not a link into vim-config → make vim"; ok=0; }; \
	s="$$($(CFG) status --short 2>/dev/null)"; [ -z "$$s" ] || { echo "✗ dotfiles: uncommitted drift → make sync"; echo "$$s"; ok=0; }; \
	if [ -d $(PROFILES)/.git ]; then \
	    s="$$(git -C $(PROFILES) status --short 2>/dev/null)"; [ -z "$$s" ] || { echo "✗ claude-profiles: uncommitted drift → make sync"; echo "$$s"; ok=0; }; \
	    for f in $(PROFILES)/*/settings.json; do jq -e '$(SECRETS)' $$f >/dev/null && { echo "✗ $$f: secrets in permissions → make sync"; ok=0; }; done; \
	else echo "✗ ~/.claude-profiles not cloned → make private"; ok=0; fi; \
	gh auth status >/dev/null 2>&1 || echo "todo: gh auth login && gh auth setup-git"; \
	ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | grep -q successfully || echo "todo (optional, https via gh works): ssh-keygen -t ed25519 && gh ssh-key add ~/.ssh/id_ed25519.pub"; \
	[ -r $(HOME)/.zshrc.local ] || echo "todo: cp ~/.zshrc.local.example ~/.zshrc.local (ZEALOT_PYLON_TOKEN)"; \
	for p in $(PROFILES)/*/; do [ -f $$p.claude.json ] || echo "todo: CLAUDE_CONFIG_DIR=$$p claude  (login)"; done; \
	[ $$ok = 1 ] && echo "✓ converged"

sync: ## scrub secrets from profile settings; stage changes in both repos
	@for f in $(PROFILES)/*/settings.json; do \
	    jq '.permissions.allow |= map(select(test("[A-Z_]{3,}=") | not))' $$f > $$f.tmp && mv $$f.tmp $$f; done
	$(CFG) add -u
	git -C $(PROFILES) add -A
	@echo "== dotfiles";        $(CFG) status --short
	@echo "== claude-profiles"; git -C $(PROFILES) status --short
	@echo "then: cfg commit -m '...' && cfg push;  git -C ~/.claude-profiles commit -m '...' && git -C ~/.claude-profiles push"

help: ## this
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-11s %s\n", $$1, $$2}'
