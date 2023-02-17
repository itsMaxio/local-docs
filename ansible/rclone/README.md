# Variable config spreadsheet for Rclone

## Before start 
Make sure that `file_src` in `update.yaml` is set up correctly

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
ansible-playbook -i private/inventory.yaml rclone/main.yaml
```