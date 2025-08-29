# Restic Backup Role

Role path: `roles_local/restic_backup`

Usage:

```yaml
# playbook.yaml
- hosts: all
  roles:
     - restic_backup

# Required variables
restic_backup__ssh_user: ""               # SSH user
restic_backup__ssh_host_alias: ""         # SSH host alias, e.g. "backup-host"
restic_backup__ssh_hostname: ""           # Hostname or IP of the remote server
restic_backup__ssh_key: ""                # SSH key
restic_backup__repository_path: ""        # Repository path, e.g. sftp:<ssh_alias>:<repo_location_on_server>
restic_backup__repository_password: ""    # Password for the repository
restic_backup__healthcheck_url: ""        # URL for healthchecks.io integration

# Optional variables (with defaults)
restic_backup__script_dir: "/opt/restic-backup" # Directory to store backup scripts

restic_backup__user: "root"           # SSH user
restic_backup__group: "root"          # SSH group
restic_backup__ssh_key_path: "/root/.ssh" # Path to private SSH key

restic_backup__stacks_dir: "/docker"      # Directory for Docker stacks

restic_backup__retention_keep_last: 5     # Number of backups to keep

restic_backup__logs_dir: "/var/log/docker-backup-logs" # Directory for backup logs
restic_backup__logs_keep: 10              # Number of log files to keep

restic_backup__progress_fps: 1            # Progress display frequency
```
