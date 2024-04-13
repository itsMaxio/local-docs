# Variable config spreadsheet for Installing Docker

## Before start

## How to start

Move to the `ansible` directory

```bash
cd ansible
```

Run it

```bash
ansible-playbook -kK -i 0_config/inventory.yaml -e @0_config/vars.yaml install-docker/main.yaml
```
