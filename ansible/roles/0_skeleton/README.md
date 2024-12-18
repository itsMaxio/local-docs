# Variable config spreadsheet for <NAME>
## Before start 

Add variables to `vars.yaml` file:

```yaml
...



...
```

## How to start

Move to the `ansible` directory

```bash
cd ansible
```
Run it

```bash
ansible-playbook -kK -i 0_config/inventory.yaml -e @0_config/vars.yaml <PATH>/main.yaml
```