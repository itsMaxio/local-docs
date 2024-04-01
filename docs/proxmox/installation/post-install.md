# Configuration Proxmox
> v8.1.3 EXT4
## Increase storage

Do it after installation

### Delete storage from 
>GUI

Go to `Datacenter > Storage` then press on `local-lvm` and press `Remove`

### Resize old storage to new size 
>SHELL

Go to `Datacenter > <your proxmox server> > Shell` and copy this commands:

```bash
lvremove /dev/pve/data
```

```bash
lvresize -l +100%FREE /dev/pve/root
```

```bash
resize2fs /dev/mapper/pve-root
```

### Change `local` to new data drive
>GUI

Go to `Datacenter > Storage` click on `local` then `edit` and then change `Content` and add `Disk image` and `Container`

## Repositories

###