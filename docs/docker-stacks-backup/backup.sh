#!/bin/bash
set -euo pipefail
IFS=$'\n'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"

if [[ ! -r "$CONFIG_FILE" ]]; then
    echo "[$(date -Iseconds)] ERROR: brak pliku konfiguracyjnego $CONFIG_FILE" >&2
    exit 1
fi
source "$CONFIG_FILE"

ping_start()
{
    curl -fsS -m 30 "$HEALTHCHECKS_URL/start"
}

ping_success()
{
    curl -fsS -m 30 "$HEALTHCHECKS_URL/success"
}

ping_fail()
{
    curl -fsS -m 30 "$HEALTHCHECKS_URL/fail"
}

docker_compose_down()
{
    local service_dir="$1"
    echo "[$(date -Iseconds)] DOCKER_COMPOSE: Stopping: $service_dir" >> "$LOG_FILE"
    if ! docker compose -f "$service_dir/compose.yaml" down >>"$LOG_FILE" 2>&1; then
        echo "[$(date -Iseconds)] ERROR: down $service_dir" >> "$LOG_FILE"
        ping_fail
        return 1
    fi
}

docker_compose_up()
{
    local service_dir="$1"
    echo "[$(date -Iseconds)] DOCKER_COMPOSE: Starting: $service_dir" >> "$LOG_FILE"
    if ! docker compose -f "$service_dir/compose.yaml" up -d >>"$LOG_FILE" 2>&1; then
        echo "[$(date -Iseconds)] ERROR: up $service_dir" >> "$LOG_FILE"
        ping_fail
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
    if ! restic backup "$service_dir" --tag "$tag" --cleanup-cache --verbose >>"$LOG_FILE" 2>&1; then
        echo "[$(date -Iseconds)] ERROR: backup $service_dir" >> "$LOG_FILE"
        ping_fail
        return 1
    fi

    restic forget --prune \
                  --keep-daily "${RESTIC_KEEP_DAILY:-7}" \
                  --keep-weekly "${RESTIC_KEEP_WEEKLY:-4}" \
                  --keep-monthly "${RESTIC_KEEP_MONTHLY:-6}" \
                  >>"$LOG_FILE" 2>&1 || true

    echo "[$(date -Iseconds)] RESTIC: Checking repo after backup of $service_dir" >> "$LOG_FILE"
    if ! restic check --read-data >>"$LOG_FILE" 2>&1; then
        echo "[$(date -Iseconds)] WARNING: restic check failed for $service_dir" >> "$LOG_FILE"
        ping_fail
        return 1
    fi
}

LOCKFILE="/var/run/$(basename "$0").lock"
exec 200>"$LOCKFILE"
flock -n 200 || { echo "[$(date -Iseconds)] ERROR: skrypt już działa" >&2; exit 1; }

ping_start
echo "[$(date -Iseconds)] SCRIPT: Backup start" >> "$LOG_FILE"

for service_dir in "$DOCKER_STACKS_LOCATION"/*/; do
    echo -e "\n" >> "$LOG_FILE"

    mapfile -t running < <(docker compose -f "$service_dir/compose.yaml" ps --services --filter "status=running")
    if (( ${#running[@]} )); then
        docker_compose_down "$service_dir"
        restic_backup       "$service_dir"
        docker_compose_up   "$service_dir"
    else
        restic_backup       "$service_dir"
    fi
done

echo "[$(date -Iseconds)] SCRIPT: Backup completed" >> "$LOG_FILE"
ping_success
