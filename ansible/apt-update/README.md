# Variable config spreadsheet for Apt Update

## Before start 
Make sure that `file_src` in `update.yaml` is set up correctly

## How to start

Move to the `ansible` directory

```bash
cd ansible
```
Run it

```bash
ansible-playbook -i private/inventory.yaml apt-update/main.yaml
```