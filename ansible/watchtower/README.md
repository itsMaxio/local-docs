# Variable config spreadsheet for Watchtower

## Before start 

Add variables to `vars.yaml` file:

```yaml
...

watchtower:
  name: "watchtower-update"
  gotify_ip: "192.168.0.100"
  gotify_token: "abc123"

...
```

## How to start

Move to the `ansible` directory

```bash
cd ansible
```
Run it

```bash
ansible-playbook -kK -i 0_config/inventory.yaml -e @0_config/vars.yaml watchtower/main.yaml
```