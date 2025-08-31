#!/bin/bash

set -euo pipefail

readonly MAGENTA='\033[95m'
readonly GREEN='\033[92m'
readonly RED='\033[91m'
readonly YELLOW='\033[93m'
readonly BLUE='\033[94m'
readonly NC='\033[0m'

_log() {
  echo -e "${MAGENTA}[$1]${NC} $2"
}

_success() {
  echo -e "${GREEN}[$1]${NC} $2"
}

_error() {
  echo -e "${RED}[$1]${NC} $2"
  exit 1
}

_warn() {
  echo -e "${YELLOW}[$1]${NC} $2"
}

load_environment() {
  GIT_USER_NAME=${GIT_USER_NAME:-"$(git config --global user.name 2>/dev/null || echo '')"}
  GIT_USER_EMAIL=${GIT_USER_EMAIL:-"$(git config --global user.email 2>/dev/null || echo '')"}
  WINDOWS_USERNAME=${WINDOWS_USERNAME:-"$(whoami)"}
  SSH_KEY_NAME=${SSH_KEY_NAME:-"$GIT_USER_NAME"}

  if [[ -z "$GIT_USER_NAME" || -z "$GIT_USER_EMAIL" ]]; then
    _warn "FUNCTIONS" "Git user information not found. Some configurations may not work properly."
    _log "FUNCTIONS" "Run 'git config --global user.name \"Your Name\"' and 'git config --global user.email \"your@email.com\"'"
  fi
}

expand_placeholder() {
  local source_file="$1"
  local dest_file="$2"

  if [ ! -f "$source_file" ]; then
    _warn "FUNCTIONS" "$source_file not found"
    return 1
  fi

  _log "FUNCTIONS" "Expanding placeholders in $source_file -> $dest_file"

  local temp_file=$(mktemp)
  cp "$source_file" "$temp_file"

  sed -i "s|{{GIT_USER_NAME}}|$GIT_USER_NAME|g" "$temp_file"
  sed -i "s|{{GIT_USER_EMAIL}}|$GIT_USER_EMAIL|g" "$temp_file"
  sed -i "s|{{HOME}}|$HOME|g" "$temp_file"
  sed -i "s|{{WINDOWS_USERNAME}}|$WINDOWS_USERNAME|g" "$temp_file"
  sed -i "s|{{SSH_KEY_NAME}}|$SSH_KEY_NAME|g" "$temp_file"

  cp "$temp_file" "$dest_file" && rm "$temp_file"
}
