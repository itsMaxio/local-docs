# Variable config spreadsheet for Pihole Update

## Before start 

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
ansible-playbook -kK -i 0_config/inventory.yaml -e @0_config/vars.yaml pihole-update/main.yaml
```