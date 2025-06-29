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

ping_log() {
  curl -fsS -m 60 \
    -H "Content-Type: text/plain" --data-binary @"$LOG_FILE" "$HEALTHCHECKS_URL/log" >/dev/null || true
}

docker_compose_down()
{
  local service_dir="$1"
  echo "[$(date -Iseconds)] DOCKER_COMPOSE: Stopping: $service_dir" >> "$LOG_FILE"
  (
      cd "$service_dir" || return 1
      if ! docker compose stop >>"$LOG_FILE" 2>&1; then
          echo "[$(date -Iseconds)] ERROR: Stopping: $service_dir" >> "$LOG_FILE"
          return 1
      fi
  )
}

docker_compose_up()
{
  local service_dir="$1"
  echo "[$(date -Iseconds)] DOCKER_COMPOSE: Starting: $service_dir" >> "$LOG_FILE"
  (
      cd "$service_dir" || return 1
      if ! docker compose start >>"$LOG_FILE" 2>&1; then
          echo "[$(date -Iseconds)] ERROR: Starting: $service_dir" >> "$LOG_FILE"
          return 1
      fi
  )
}

restic_backup()
{
  local service_dir="$1"
  local service_name="$(basename "${service_dir%/}")"

  echo "[$(date -Iseconds)] RESTIC: Backup start: $service_dir (tag: $service_name)" >> "$LOG_FILE"
  if ! restic -r "$RESTIC_REPOSITORY" backup "$service_dir" --tag "$service_name" --cleanup-cache --verbose >>"$LOG_FILE" 2>&1; then
      echo "[$(date -Iseconds)] ERROR: backup $service_dir" >> "$LOG_FILE"
      return 1
  fi
}

restic_forget() {
  echo "[$(date -Iseconds)] RESTIC: Starting retention policy" >> "$LOG_FILE"
  restic -r "$RESTIC_REPOSITORY" forget --group-by tags \
                --keep-last "${RESTIC_KEEP_LAST}" \
                --prune \
                >>"$LOG_FILE" 2>&1 || true
  echo "[$(date -Iseconds)] RESTIC: Ending retention policy" >> "$LOG_FILE"
}

restic_check() {
  echo "[$(date -Iseconds)] RESTIC: Starting checking repository integrity" >> "$LOG_FILE"
  restic -r "$RESTIC_REPOSITORY" check >>"$LOG_FILE" 2>&1
  echo "[$(date -Iseconds)] RESTIC: Ending checking repository integrity" >> "$LOG_FILE"
}

LOCKFILE="/tmp/$(basename "$0").lock"
exec 200>"$LOCKFILE"
if ! flock -n 200; then
  echo "[$(date -Iseconds)] ERROR: Backup is already working" >&2
  exit 1
fi

global_error=0

echo -e "[$(date -Iseconds)] SCRIPT: Backup starting..." >> "$LOG_FILE"
ping_start

if ! restic -r "$RESTIC_REPOSITORY" snapshots --quiet >/dev/null 2>&1; then
  echo "[$(date -Iseconds)] ERROR: Repository does not exists: $RESTIC_REPOSITORY" >&2
  exit 1
fi

for service_dir in "$DOCKER_STACKS_LOCATION"/*/; do
  echo -e "\n[$(date -Iseconds)] SCRIPT: Processing: $service_dir" >> "$LOG_FILE"

  service_error=0

  mapfile -t running < <(docker compose -f "$service_dir/compose.yaml" ps --services --filter "status=running")
  if [[ ${#running[@]} -gt 0 && -n "${running[0]}" ]]; then

    if ! docker_compose_down "$service_dir"; then
        global_error=1
        service_error=1
        echo "[$(date -Iseconds)] SCRIPT: Skipping backup for: $service_dir (error with docker compose)" >> "$LOG_FILE"
        continue
    fi

    if ! restic_backup "$service_dir"; then
        global_error=1
    fi

    if (( service_error == 0 )) ; then
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
  echo "[$(date -Iseconds)] SCRIPT: Backup completed successfully" >> "$LOG_FILE"
  ping_success
  ping_log
else
  echo "[$(date -Iseconds)] SCRIPT: Backup completed with errors" >> "$LOG_FILE"
  ping_fail
  ping_log
fi