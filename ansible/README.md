# Ansible installation and configuration

## Ansible config file

Create an `ansible.cfg` file in your project root directory or copy inventory file (if available):

```bash
cp example.ansible.cfg ansible.cfg
```

### Inventory file

Create or navigate to the `inventories` directory (defined in `ansible.cfg`):

```bash
mkdir -p inventories && cd inventories
```

Copy the example inventory file (if available):

```bash
cp example.inventory.yaml inventory.yaml
```

## Playbook execution

Available Playbooks:

- update_debian.yaml  
  Available tags:
  - `update` - Refresh apt package cache
  - `upgrade` - Perform full system upgrade
  - `reboot` - Reboot if required (conditional)
  
### Basic commands

Default execution (all hosts in inventory):

```bash
ansible-playbook playbooks/PLAYBOOK.yaml
```

With `sudo` password prompt:

```bash
ansible-playbook playbooks/PLAYBOOK.yaml --ask-become-pass
```

### Target specific hosts

By hostname:

```bash
ansible-playbook playbooks/PLAYBOOK.yaml --limit "host_name"
```

By IP address:

```bash
ansible-playbook playbooks/PLAYBOOK.yaml --limit "192.168.1.100"
```

### Tag-Based execution

Run with specific tag:

```bash
ansible-playbook playbooks/PLAYBOOK.yaml --tags "tag1"
```

Run with multiple tags:

```bash
ansible-playbook playbooks/PLAYBOOK.yaml --tags "tag1, tag2"
```

### Testing and troubleshooting

Dry run mode (simulation):

```bash
ansible-playbook playbooks/PLAYBOOK.yaml --check --diff
```

Dry run mode with `sudo` (simulation):

```bash
ansible-playbook playbooks/PLAYBOOK.yaml --ask-become-pass --check --diff
```

> Enable detailed debugging with -vvv:

<!-- ### Vars file

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
- [Rclone](rclone/README.md) -->