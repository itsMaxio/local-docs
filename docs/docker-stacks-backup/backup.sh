#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"

if [[ ! -r "$CONFIG_FILE" ]]; then
  echo "[$(date -Iseconds)] ERROR: No config file: $CONFIG_FILE" >&2
  exit 1
fi

source "$CONFIG_FILE"
export RESTIC_PASSWORD

if [[ ! -d "$LOG_FILES_DIRECTORY" ]]; then
  mkdir -p "$LOG_FILES_DIRECTORY"
fi

LOG_FILE="$LOG_FILES_DIRECTORY/log-$(date +"%Y-%m-%d_%H_%M").txt"
touch "$LOG_FILE"

log() {
  echo "" >> "$LOG_FILE"
  echo "[$(date -Iseconds)] $*" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
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
  log "DOCKER_COMPOSE: Stopping: $service_dir"
  (
    cd "$service_dir" || return 1
    if ! docker compose stop >>"$LOG_FILE" 2>&1; then
      log "ERROR: Stopping: $service_dir"
      return 1
    fi
  )
}

docker_compose_up() {
  local service_dir="$1"
  log "DOCKER_COMPOSE: Starting: $service_dir"
  (
    cd "$service_dir" || return 1
    if ! docker compose start >>"$LOG_FILE" 2>&1; then
      log "ERROR: Starting: $service_dir"
      return 1
    fi
  )
}

restic_backup() {
  local service_dir="$1"
  local service_name="$(basename "${service_dir%/}")"

  log "RESTIC: Backup start: $service_dir (tag: $service_name)"
  if ! restic -r "$RESTIC_REPOSITORY" backup "$service_dir" --tag "$service_name" --cleanup-cache --verbose >>"$LOG_FILE" 2>&1; then
    log "ERROR: backup $service_dir"
    return 1
  fi
}

restic_forget() {
  log "RESTIC: Starting retention policy"
  restic -r "$RESTIC_REPOSITORY" forget --group-by tags \
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
  echo "[$(date -Iseconds)] ERROR: Backup is already working" >&2
  exit 1
fi

global_error=0

log "SCRIPT: Backup starting..."
ping_start

if ! restic -r "$RESTIC_REPOSITORY" snapshots --quiet >/dev/null 2>&1; then
  echo "[$(date -Iseconds)] ERROR: Repository does not exist: $RESTIC_REPOSITORY" >&2
  exit 1
fi

for service_dir in "$DOCKER_STACKS_LOCATION"/*/; do
  log "SCRIPT: Processing: $service_dir"

  service_error=0

  mapfile -t running < <(docker compose -f "$service_dir/compose.yaml" ps --services --filter "status=running")
  if [[ ${#running[@]} -gt 0 && -n "${running[0]}" ]]; then

    if ! docker_compose_down "$service_dir"; then
      global_error=1
      service_error=1
      log "SCRIPT: Skipping backup for: $service_dir (error with docker compose)"
      continue
    fi

    if ! restic_backup "$service_dir"; then
      global_error=1
    fi

    if (( service_error == 0 )); then
      if ! docker_compose_up "$service_dir"; then
        global_error=1
        service_error=1
      fi
    fi
  else
    if ! restic_backup "$service_dir"; then
      global_error=1
    fi
  fi
done

if (( global_error == 0 )); then
  restic_forget
  restic_check
  log "SCRIPT: Backup completed successfully"
  ping_success
  ping_log
else
  log "SCRIPT: Backup completed with errors"
  ping_fail
  ping_log
fi
