# Variable config spreadsheet for Pihole Update

## Before start 
Make sure that `file_src` in `update.yaml` is set up correctly

Add variables to `vars.yaml` file:

```yaml
...

pihole:
  old_port: 80
  new_port: 8080

...
```

## How to start

Move to the `ansible` directory

```bash
cd ansible
```
Run it

```bash
ansible-playbook -i private/inventory.yaml pihole-update/main.yaml
```