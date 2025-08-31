#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/functions.sh"

log() {
  _log "CI" "$1"
}

success() {
  _success "CI" "$1"
}

error() {
  _error "CI" "$1"
}

warn() {
  _warn "CI" "$1"
}

CONTAINER_ID=""
DRY_RUN=false

cleanup() {
  if [ -n "${CONTAINER_ID:-}" ]; then
    log "Stopping and removing container..."
    docker stop "$CONTAINER_ID" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_ID" >/dev/null 2>&1 || true
  fi
}

format_files() {
  local dry_run_flag=""
  if [ "$DRY_RUN" = true ]; then
    dry_run_flag="--dry-run"
  fi

  log "Formatting Shell files (.sh)..."
  docker exec "$CONTAINER_ID" find /workspaces -name "*.sh" -type f -exec shfmt -w {} \; || warn "Issues occurred while formatting Shell files"

  log "Formatting Fish files (.fish)..."
  docker exec "$CONTAINER_ID" bash -c '
        for file in $(find /workspaces -name "*.fish" -type f); do
            fish_indent < "$file" > "${file}.tmp" && mv "${file}.tmp" "$file" || echo "Warning：Failed to format $file"
        done
    ' || warn "Issues occurred while formatting Fish files"

  log "Formatting Lua files (.lua)..."
  docker exec "$CONTAINER_ID" bash -c '
        if [ -f /workspaces/stylua.toml ]; then
            find /workspaces -name "*.lua" -type f -exec stylua --config-path /workspaces/stylua.toml {} \;
        else
            find /workspaces -name "*.lua" -type f -exec stylua {} \;
        fi
    ' || warn "Issues occurred while formatting Lua files"

  log "Formatting JSON files (.json)..."
  docker exec "$CONTAINER_ID" bash -c '
        find /workspaces -name "*.json" -type f -exec prettier --write {} \;
    ' || warn "Issues occurred while formatting JSON files"

  log "Formatting PowerShell files (.ps1)..."
  docker exec "$CONTAINER_ID" bash -c '
        for file in $(find /workspaces -name "*.ps1" -type f); do
            pwsh -Command "
                try {
                    \$lines = Get-Content \"$file\"
                    \$result = @()

                    foreach (\$line in \$lines) {
                        \$cleaned = \$line -replace \"\\t\", \"    \"
                        \$cleaned = \$cleaned.TrimEnd()

                        if (\$cleaned -ne \"\") {
                            \$result += \$cleaned
                        } elseif (\$result.Count -gt 0 -and \$result[-1] -ne \"\") {
                            \$result += \"\"
                        }
                    }

                    while (\$result.Count -gt 1 -and \$result[-1] -eq \"\") {
                        \$result = \$result[0..(\$result.Count - 2)]
                    }

                    \$result | Set-Content \"$file\"
                    Write-Host \"Formatted：$file\"
                } catch {
                    Write-Host \"Warning：Failed to format $file - \$_\"
                }
            "
        done
    ' || warn "Issues occurred while formatting PowerShell files"
}

main() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      error "Unknown option：$1"
      exit 1
      ;;
    esac
  done

  trap cleanup EXIT

  success "⚙️ ci.sh"

  if ! command -v docker >/dev/null 2>&1; then
    error "Docker not found. Please install Docker."
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    error "Docker is not running. Please start Docker."
    exit 1
  fi

  log "Building Docker image for CI..."
  if ! docker build -f Dockerfile.ci -t dotfiles-ci .; then
    error "Failed to build Docker image"
    exit 1
  fi
  success "Docker image build completed"

  log "Starting CI container..."
  CONTAINER_ID=$(docker run -d \
    --label dotfiles-ci \
    -v "$(pwd):/workspaces" \
    --workdir /workspaces \
    dotfiles-ci \
    sleep 1800)

  if [ -z "$CONTAINER_ID" ]; then
    error "Failed to start container"
    exit 1
  fi

  success "CI container started (ID：${CONTAINER_ID:0:12})"

  format_files

  success "✅ All file CI processing completed"
}

main "$@"
