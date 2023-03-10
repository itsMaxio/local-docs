# Ansible installation and configuration

## YAML Files

To run this project, you will need to create two `.yaml` files:
* `inventory.yaml`
* `vars.yaml`

## Environment Variables

### Inventory file

Move to the `0_config` directory:

```bash
cd 0_config
```

Copy `example.inventory.yaml` file:

```bash
cp example.inventory.yaml inventory.yaml
```

Edit variables in `inventory.yaml` file:

```yaml
all:
  hosts:
    host_name: #custom hostname
      ansible_host: ip
      ansible_connection: ssh
      ansible_user: maxio 
      ansible_password: password # optimal
      ansible_become_password: sudopassword # optimal
```

### Vars file

Copy `example.inventory.yaml` file:

```bash
cp example.vars.yaml vars.yaml
```

Edit variables in `vars.yaml` file:
> for every `new var` see individual file:

List of possible configurations:

- [Apt Update](apt-update/README.md)
- [Watchtower](watchtower/README.md)
- [PiHole](pihole-update/README.md)
- [Rclone](rclone/README.md)