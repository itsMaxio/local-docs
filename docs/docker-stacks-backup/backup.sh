#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"

if [[ ! -r "$CONFIG_FILE" ]]; then
    echo "[$(date -Iseconds)] ERROR: brak pliku konfiguracyjnego $CONFIG_FILE" >&2
    exit 1
fi
source "$CONFIG_FILE"

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

docker_compose_down()
{
    local service_dir="$1"
    echo "[$(date -Iseconds)] DOCKER_COMPOSE: Stopping: $service_dir" >> "$LOG_FILE"
    cd "$service_dir"
    if ! docker compose down >>"$LOG_FILE" 2>&1; then
        echo "[$(date -Iseconds)] ERROR: down $service_dir" >> "$LOG_FILE"
        return 1
    fi
}

docker_compose_up()
{
    local service_dir="$1"
    echo "[$(date -Iseconds)] DOCKER_COMPOSE: Starting: $service_dir" >> "$LOG_FILE"
    cd "$service_dir"
    if ! docker compose up -d >>"$LOG_FILE" 2>&1; then
        echo "[$(date -Iseconds)] ERROR: up $service_dir" >> "$LOG_FILE"
        return 1
    fi
}

restic_backup()
{
    local service_dir="$1"
    local service_name
    service_name=$(basename "${service_dir%/}")
    local tag="${service_name}-$(date +%Y%m%dT%H%M%S)"

    echo "[$(date -Iseconds)] RESTIC: Backup start: $service_dir (tag: $tag)" >> "$LOG_FILE"
    if ! restic backup "$service_dir" --tag "$tag" --cleanup-cache >>"$LOG_FILE" 2>&1; then
        echo "[$(date -Iseconds)] ERROR: backup $service_dir" >> "$LOG_FILE"
        return 1
    fi
}

restic_forget() {
    echo "[$(date -Iseconds)] RESTIC: Applying retention policy" >> "$LOG_FILE"
    restic forget --prune \
                  --keep-daily "${RESTIC_KEEP_DAILY:-7}" \
                  --keep-weekly "${RESTIC_KEEP_WEEKLY:-4}" \
                  --keep-monthly "${RESTIC_KEEP_MONTHLY:-6}" \
                  >>"$LOG_FILE" 2>&1 || true
}

restic_check() {
    echo "[$(date -Iseconds)] RESTIC: Checking repository integrity" >> "$LOG_FILE"
    restic check >>"$LOG_FILE" 2>&1
}

LOCKFILE="/tmp/$(basename "$0").lock"
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    echo "[$(date -Iseconds)] ERROR: skrypt już działa" >&2
    exit 1
fi

global_error=0

echo -e "\n\n[$(date -Iseconds)] SCRIPT: Rozpoczęcie backupu" >> "$LOG_FILE"
ping_start

for service_dir in "$DOCKER_STACKS_LOCATION"/*/; do
    echo -e "\n[$(date -Iseconds)] Processing: $service_dir" >> "$LOG_FILE"

    service_error=0

    mapfile -t running < <(docker compose -f "$service_dir/compose.yaml" ps --services --filter "status=running")
    if (( ${#running[@]} )); then

      if ! docker_compose_down "$service_dir"; then
          global_error=1
          service_error=1
          echo "[$(date -Iseconds)] SKIPPING: Backup dla $service_dir (błąd zatrzymania)" >> "$LOG_FILE"
          continue
      fi

      if ! restic_backup "$service_dir"; then
          global_error=1
          service_error=1
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
    echo "[$(date -Iseconds)] SCRIPT: Backup zakończony sukcesem" >> "$LOG_FILE"
    ping_success
else
    echo "[$(date -Iseconds)] SCRIPT: Backup zakończony z BŁĘDAMI" >> "$LOG_FILE"
    ping_fail
fi