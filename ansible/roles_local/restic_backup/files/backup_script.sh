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
export RESTIC_PROGRESS_FPS

LOGS_DIR=$(realpath -s "$LOGS_DIR")
if [[ ! -d "$LOGS_DIR" ]]; then
  mkdir -p "$LOGS_DIR"
fi

LOG_FILE="$LOGS_DIR/log-$(date +"%Y-%m-%d_%H_%M").txt"
touch "$LOG_FILE"

log() 
{
  local newline=0

  if [[ "$1" = "--newline" ]]; then
    newline=1
    shift
  fi

  local time="[$(date -Iseconds)]"

  {
    if (( newline == 1 )); then
      echo ""
    fi

    for line in "$@"; do
      echo -e "$time $line"
    done

    if (( newline == 1 )); then
      echo ""
    fi
  } >> "$LOG_FILE"
}

find "$LOGS_DIR" -type f -name '*.txt' -printf '%T@ %p\0' |
  sort -z -nr |
  tail -z -n +$((LOGS_KEEP + 1)) |
  cut -z -d' ' -f2- |
  xargs -0 -r rm --

ping_start()
{
  curl -fsS -m 30 "$HEALTHCHECK_URL/start" >/dev/null || true
}

ping_success()
{
  curl -fsS -m 30 "$HEALTHCHECK_URL" >/dev/null || true
}

ping_fail()
{
  curl -fsS -m 30 "$HEALTHCHECK_URL/fail" >/dev/null || true
}

ping_log()
{
  curl -fsS -m 60 -H "Content-Type: text/plain" --data-binary @"$LOG_FILE" "$HEALTHCHECK_URL/log" >/dev/null || true
}

docker_compose_stop()
{
  local service_dir="$1"
  log --newline "DOCKER_COMPOSE_STOP: Stopping: $service_dir"
  (
    cd "$service_dir" || return 1
    if ! docker compose stop >>"$LOG_FILE" 2>&1; then
      log "DOCKER_COMPOSE_STOP_ERROR: Stopping: $service_dir"
      return 1
    fi
  )
}

docker_compose_start() {
  local service_dir="$1"
  log --newline "DOCKER_COMPOSE_START: Starting: $service_dir"

  (
    cd "$service_dir" || return 1

    if ! docker compose start >>"$LOG_FILE" 2>&1; then
      log --newline "DOCKER_COMPOSE_START: One or more services are unhealthy"

      check_health() {
        local service="$1"
        local status=$(docker inspect "$service" | jq -r '.[0].State.Health.Status // "nohealth"')
        [[ "$status" == "healthy" || "$status" == "nohealth" ]]
      }

      mapfile -t services < <(docker compose ps --quiet)
      local max_attempts=5

      for service in "${services[@]}"; do
        local attempt=1
        until check_health "$service"; do
          if (( attempt >= max_attempts )); then
            log "DOCKER_COMPOSE_START_ERROR: $service is unhealthy after $attempt attempts"
            return 1
          fi
          log "DOCKER_COMPOSE_START: $service attempt $attempt failed, retrying in $attempt sec..."
          sleep "$attempt"
          ((attempt++))
        done
      done

      log --newline "DOCKER_COMPOSE_START: All services healthy in $service_dir"
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
  log --newline "RESTIC: Starting retention policy"
  restic -r "$RESTIC_REPOSITORY" forget \
        --keep-last "${RESTIC_RETENTION_KEEP_LAST}" \
        --prune >>"$LOG_FILE" 2>&1 || true
  log --newline "RESTIC: Ending retention policy"
}

restic_check() {
  log --newline "RESTIC: Starting checking repository integrity"
  restic -r "$RESTIC_REPOSITORY" check >>"$LOG_FILE" 2>&1
  log --newline "RESTIC: Ending checking repository integrity"
}

LOCKFILE="/tmp/$(basename "$0").lock"
exec 200>"$LOCKFILE"
if ! flock -n 200; then
  log "ERROR: Backup is already working"
  ping_fail
  ping_log
  exit 1
fi

global_error=0

log --newline "SCRIPT: Backup starting..."
ping_start

if [ ! -d "$STACKS_DIR" ]; then
  log "ERROR: Docker stacks location does not exist: $STACKS_DIR"
  ping_fail
  ping_log
  exit 1
fi

if ! restic -r "$RESTIC_REPOSITORY" snapshots --quiet >/dev/null 2>&1; then
  log "ERROR: Repository does not exist: $RESTIC_REPOSITORY"
  ping_fail
  ping_log
  exit 1
fi

services_to_restart=()

log --newline "SCRIPT: Stopping services..."
for service_dir in "$STACKS_DIR"/*/; do
  log --newline "SCRIPT: Checking: $service_dir"

  mapfile -t running < <(docker compose -f "$service_dir/compose.yaml" ps --services --filter "status=running" 2>/dev/null)
  
  if [[ ${#running[@]} -gt 0 && -n "${running[0]}" ]]; then
    log "SCRIPT: Found running services in $service_dir: \n\n${running[*]}"
    
    if docker_compose_stop "$service_dir"; then
      services_to_restart+=("$service_dir")
    else
      global_error=1
    fi
  else
    log "SCRIPT: Found no services running in $service_dir"
  fi
done

how_many_services=$(ls "$STACKS_DIR" | wc -l)

log --newline "SCRIPT: There are $how_many_services services to backup, of which ${#services_to_restart[@]} are currently running:" "${services_to_restart[@]}"

log --newline "SCRIPT: Backing up entire directory: $STACKS_DIR"
if ! restic_backup "$STACKS_DIR"; then
  global_error=1
fi

log --newline "SCRIPT: Starting services..."
for service_dir in "${services_to_restart[@]}"; do
  if ! docker_compose_start "$service_dir"; then
    global_error=1
  fi
done

if (( global_error == 0 )); then
  restic_forget
  restic_check
  log --newline "SCRIPT: Backup completed successfully"
  ping_success
else
  log --newline "SCRIPT: Backup completed with errors"
  ping_fail
fi

ping_log
