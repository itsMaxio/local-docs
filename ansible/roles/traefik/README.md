# Variable config spreadsheet for Traefik Pihole DNS file

## Before start 

Add variables to `vars.yaml` file:

```yaml
...

traefik:
  traefik_url: "http://192.168.0.1:80"
  file_path: "/etc/pihole/custom.list"
  ip: 192.168.0.1

...
```

## How to start

Move to the `ansible` directory

```bash
cd ansible
```
Run it

```bash
ansible-playbook -kK -i 0_config/inventory.yaml -e @0_config/vars.yaml traefik/main.yaml
```