#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/functions.sh"

log() {
  _log "SANDBOX" "$1"
}

success() {
  _success "SANDBOX" "$1"
}

error() {
  _error "SANDBOX" "$1"
}

warn() {
  _warn "SANDBOX" "$1"
}

CONTAINER_ID=""

cleanup() {
  if [ -n "${CONTAINER_ID:-}" ] && [ "${AUTO_CLEANUP:-1}" == "1" ]; then
    log "Stopping and removing container..."
    docker stop "$CONTAINER_ID" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_ID" >/dev/null 2>&1 || true
  fi
}

main() {
  AUTO_CLEANUP=1

  if [[ $# -gt 0 && "$1" == "--keep" ]]; then
    AUTO_CLEANUP=0
    shift
  fi

  if [ "$AUTO_CLEANUP" == "1" ]; then
    trap cleanup EXIT
  fi

  success "🏖️ sandbox.sh"

  if ! command -v docker >/dev/null 2>&1; then
    error "Docker not found. Please install Docker."
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    error "Docker is not running. Please start Docker."
    exit 1
  fi

  log "Building Docker image for sandbox..."
  if ! docker build -f Dockerfile.sandbox -t dotfiles-sandbox .; then
    error "Failed to build Docker image"
    exit 1
  fi
  success "Docker image build completed"

  log "Starting sandbox container..."
  CONTAINER_ID=$(docker run -d \
    --label dotfiles-sandbox \
    -v "$(pwd):/home/sandbox/workspaces/github.com/sandbox/dotfiles" \
    --workdir /home/sandbox \
    dotfiles-sandbox \
    sleep 7200)

  if [ -z "$CONTAINER_ID" ]; then
    error "Failed to start container"
    exit 1
  fi

  success "Sandbox container started (ID：${CONTAINER_ID:0:12})"
  echo "Access container：docker exec -it ${CONTAINER_ID:0:12} bash"

  sleep 3

  log "Running setup.sh..."

  timeout 2400 docker exec "$CONTAINER_ID" bash -c "cd workspaces/github.com/sandbox/dotfiles && ./setup.sh" 2>&1
  local setup_exit_code=$?

  if [ $setup_exit_code -eq 0 ]; then
    success "✅ setup.sh completed"
    log "Starting interactive shell in container..."
    log "Type 'exit' to leave container and clean up"
    docker exec -it "$CONTAINER_ID" bash
  elif [ $setup_exit_code -eq 124 ]; then
    error "Timeout (40 minutes)"
    log "Starting debug shell in container..."
    log "Type 'exit' to leave container and clean up"
    docker exec -it "$CONTAINER_ID" bash
  else
    error "Execution error (exit code：$setup_exit_code)"
    log "Starting debug shell in container..."
    log "Type 'exit' to leave container and clean up"
    docker exec -it "$CONTAINER_ID" bash
  fi

  if [ "$AUTO_CLEANUP" == "0" ]; then
    warn "Container preserved for manual cleanup："
    warn "  Container ID：${CONTAINER_ID:0:12}"
    warn "  Access again：docker exec -it ${CONTAINER_ID:0:12} bash"
    warn "  Clean up when done：docker stop ${CONTAINER_ID:0:12} && docker rm ${CONTAINER_ID:0:12}"
  fi
}

main "$@"
