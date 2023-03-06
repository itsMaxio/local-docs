# Variable config spreadsheet for Rclone

## Before start 

Add variables to `vars.yaml` file:

```yaml
...

rclone:
  name: rclone-sync
  remote: "google"
  drive_dir: "pathin/google"
  config_dir: "/path/to/config/dir"
  copy_dir: "/path/to/copy/dir"
  puid: 1000
  pgid: 1000

...
```

## How to start

Move to the `ansible` directory

```bash
cd ansible
```
Run it

```bash
ansible-playbook -kK -i 0_config/inventory.yaml -e @0_config/vars.yaml rclone/main.yaml
```