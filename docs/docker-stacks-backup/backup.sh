#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"

if [[ ! -r "$CONFIG_FILE" ]]; then
  echo "[$(date -Iseconds)] ERROR: No config file: $CONFIG_FILE" >&2
  exit 1
fi

source "$CONFIG_FILE"
export RESTIC_PASSWORD

LOG_FILES_DIRECTORY=$(realpath -s "$LOG_FILES_DIRECTORY")
if [[ ! -d "$LOG_FILES_DIRECTORY" ]]; then
  mkdir -p "$LOG_FILES_DIRECTORY"
fi

LOG_FILE="$LOG_FILES_DIRECTORY/log-$(date + "%Y-%m-%d_%H_%M").txt"
touch "$LOG_FILE"

log() {
  time="[$(date -Iseconds)]"
  {
    echo ""
    for line in "$@"; do
      echo "$time $line"
    done
    echo ""
  } >> "$LOG_FILE"
}

find "$LOG_FILES_DIRECTORY" -type f -name '*.txt' -printf '%T@ %p\0' |
  sort -z -nr |
  tail -z -n +$((LOG_FILES_KEEP + 1)) |
  cut -z -d' ' -f2- |
  xargs -0 -r rm --

ping_start()
{
  curl -fsS -m 30 "$HEALTHCHECKS_URL/start" >/dev/null || true
}

ping_success()
{
  curl -fsS -m 30 "$HEALTHCHECKS_URL" >/dev/null || true
}

ping_fail()
{
  curl -fsS -m 30 "$HEALTHCHECKS_URL/fail" >/dev/null || true
}

ping_log() 
{
  curl -fsS -m 60 -H "Content-Type: text/plain" --data-binary @"$LOG_FILE" "$HEALTHCHECKS_URL/log" >/dev/null || true
}

docker_compose_down()
{
  local service_dir="$1"
  log "DOCKER_COMPOSE_DOWN: Stopping: $service_dir"
  (
    cd "$service_dir" || return 1
    if ! docker compose stop >>"$LOG_FILE" 2>&1; then
      log "DOCKER_COMPOSE_DOWN_ERROR: Stopping: $service_dir"
      return 1
    fi
  )
}

docker_compose_up() {
  local service_dir="$1"
  log "DOCKER_COMPOSE_UP: Starting: $service_dir"
  (
    cd "$service_dir" || return 1
    if ! docker compose start >>"$LOG_FILE" 2>&1; then
      log "DOCKER_COMPOSE_UP_ERROR: Problem starting: $service_dir"
      return 1
    fi
  )
}

restic_backup() {
  local dir_to_backup="$1"

  log "RESTIC: Backup start: $dir_to_backup"
  if ! restic -r "$RESTIC_REPOSITORY" backup "$dir_to_backup" --cleanup-cache --verbose >>"$LOG_FILE" 2>&1; then
    log "RESTIC_ERROR: Error while backing up: $dir_to_backup"
    return 1
  fi
}

restic_forget() {
  log "RESTIC: Starting retention policy"
  restic -r "$RESTIC_REPOSITORY" forget \
        --keep-last "${RESTIC_KEEP_LAST}" \
        --prune >>"$LOG_FILE" 2>&1 || true
  log "RESTIC: Ending retention policy"
}

restic_check() {
  log "RESTIC: Starting checking repository integrity"
  restic -r "$RESTIC_REPOSITORY" check >>"$LOG_FILE" 2>&1
  log "RESTIC: Ending checking repository integrity"
}

LOCKFILE="/tmp/$(basename "$0").lock"
exec 200>"$LOCKFILE"
if ! flock -n 200; then
  log " ERROR: Backup is already working"
  exit 1
fi

global_error=0

log "SCRIPT: Backup starting..."
ping_start

if ! restic -r "$RESTIC_REPOSITORY" snapshots --quiet >/dev/null 2>&1; then
  log "ERROR: Repository does not exist: $RESTIC_REPOSITORY"
  exit 1
fi

services_to_restart=()

log "SCRIPT: Stopping services..."
for service_dir in "$DOCKER_STACKS_LOCATION"/*/; do
  log "SCRIPT: Checking: $service_dir"

  mapfile -t running < <(docker compose -f "$service_dir/compose.yaml" ps --services --filter "status=running" 2>/dev/null)
  
  if [[ ${#running[@]} -gt 0 && -n "${running[0]}" ]]; then
    log "SCRIPT: Found running services in $service_dir: ${running[*]}"
    
    if docker_compose_down "$service_dir"; then
      services_to_restart+=("$service_dir")
      log "SCRIPT: Marked for restart: $service_dir"
    else
      global_error=1
    fi
  fi
done

how_many_services=$(ls "$DOCKER_STACKS_LOCATION"| wc -l)

log "SCRIPT: There are ${#how_many_services[@]} services to backup, of which ${#services_to_restart[@]} are currently running:" "${services_to_restart[@]}"

log "SCRIPT: Backing up entire directory: $DOCKER_STACKS_LOCATION"
if ! restic_backup "$DOCKER_STACKS_LOCATION"; then
  global_error=1
fi

log "SCRIPT: Starting services..."

for service_dir in "${services_to_restart[@]}"; do
  if ! docker_compose_up "$service_dir"; then
    global_error=1
  fi
done

if (( global_error == 0 )); then
  restic_forget
  restic_check
  log "SCRIPT: Backup completed successfully"
  ping_success
else
  log "SCRIPT: Backup completed with errors"
  ping_fail
fi
  
ping_log