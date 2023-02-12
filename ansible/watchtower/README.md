# Variable config spreadsheet for Watchtower

## Before start 
Make sure that `file_src` in `update.yaml` is set up correctly

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
ansible-playbook -i private/inventory.yaml watchtower/main.yaml
```