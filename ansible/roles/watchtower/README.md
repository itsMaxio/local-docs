# Variable config spreadsheet for Watchtower

## Before start 

Add variables to `vars.yaml` file:

```yaml
...

watchtower:
  name: "watchtower-update"
  telegram_token: "aabbccdd:11223344"
  telegram_chat_id: "123456789"

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