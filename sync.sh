#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/functions.sh"

log() {
  _log "SYNC" "$1"
}

success() {
  _success "SYNC" "$1"
}

main() {
  success "🔄 sync.sh"

  log "Syncing dotfiles configurations..."

  if [ ! -f "./fish/config.fish" ]; then
    echo "Error：This script must be run from the dotfiles directory."
    exit 1
  fi

  log "Loading environment variables..."
  load_environment

  log "Syncing Fish shell configuration..."
  mkdir -p ~/.config/fish/conf.d ~/.config/fish/functions

  expand_placeholder "fish/config.fish" ~/.config/fish/config.fish || {
    log "Failed to process Fish configuration file, falling back to direct copy"
    cp fish/config.fish ~/.config/fish/ || true
  }

  if [ -d "fish/conf.d" ] && [ "$(ls -A fish/conf.d 2>/dev/null)" ]; then
    log "Syncing Fish conf.d files..."
    cp fish/conf.d/* ~/.config/fish/conf.d/
  fi

  if [ -d "fish/functions" ] && [ "$(ls -A fish/functions 2>/dev/null)" ]; then
    log "Syncing Fish functions..."
    cp fish/functions/* ~/.config/fish/functions/
  fi

  if [ -f "git/.gitconfig" ]; then
    log "Syncing Git configuration..."
    expand_placeholder "git/.gitconfig" ~/.gitconfig || {
      log "Failed to process Git configuration file, falling back to direct copy"
      cp git/.gitconfig ~/.gitconfig
    }
  fi

  if [ -f "git/gitmojis.json" ]; then
    cp git/gitmojis.json ~/.gitmojis.json || true
  fi

  if [ -f "ssh/github/config" ]; then
    log "Syncing SSH GitHub configuration..."
    mkdir -p ~/.ssh/github
    expand_placeholder "ssh/github/config" ~/.ssh/github/config || {
      log "Failed to process SSH configuration file, falling back to direct copy"
      cp ssh/github/config ~/.ssh/github/config || true
    }
  fi

  if [ -f "nvim/init.lua" ]; then
    log "Syncing Neovim configuration..."
    mkdir -p ~/.config/nvim/lua
    cp nvim/init.lua ~/.config/nvim/

    if [ -f "nvim/lua/plugins.lua" ]; then
      cp nvim/lua/plugins.lua ~/.config/nvim/lua/
    fi
  fi

  success "✅ Dotfiles configuration sync completed!"
  log "Tip：Restart your shell or run 'exec fish' to apply Fish changes."
}

main "$@"
