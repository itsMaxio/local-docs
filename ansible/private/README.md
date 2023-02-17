# Docs for `private` directory


## YAML Files

To run this project, you will need to create two `.yaml` files:
* `inventory.yaml`
* `vars.yaml`

## Environment Variables

### Inventory file

Copy `inventory.example.yaml` file:

```bash
cp inventory.example.yaml inventory.yaml
```

Edit variables in `inventory.yaml` file:

```yaml
all:
  hosts:
    host_name:
      ansible_host: ip
      ansible_connection: ssh
      ansible_user: maxio
      ansible_password: password
      ansible_become_password: sudopassword
```

### Vars file

Copy `inventory.example.yaml` file:

```bash
cp vars.example.yaml vars.yaml
```

Edit variables in `vars.yaml` file:
> for every  `new var` see individual file:

[List of possible configurations](../README.md)