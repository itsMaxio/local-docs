# After installation

## Uninstall cloud-init

Disable all services (uncheck everything except "None"):

```bash
sudo dpkg-reconfigure cloud-init
```

Uninstall the package and delete the folders

```bash
sudo dpkg-reconfigure cloud-init
sudo apt-get purge cloud-init
sudo rm -rf /etc/cloud/ && sudo rm -rf /var/lib/cloud/
```

Restart the computer

```bash
sudo reboot
```

## Import ssh keys

[Import via Windows Powershell](../../ssh/ssh-key-windows-to-linux.md)

## Install Docker via Ansible

Install Docker via this [Playbook](../../../ansible/install-docker/README.md)

## Install Qemu-guest-agent

On Linux you have to simply install the qemu-guest-agent via:

```bash
sudo apt install qemu-guest-agent
```

and then run it:

```bash
sudo systemctl start qemu-guest-agent
```

## Disable IPv6

Open `/etc/sysctl.conf` with administrator right:

```bash
sudo nano /etc/sysctl.conf
```

Add the following lines to the end of file:

```conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
```

For the settings to take effect use:

```bash
sudo sysctl -p
```

If IPv6 is still enabled after rebooting, you must create (with root privileges) the file `/etc/rc.local` and fill it with:

```bash
sudo nano /etc/rc.local
```

```bash
#!/bin/bash
# /etc/rc.local

/etc/sysctl.d
/etc/init.d/procps restart

exit 0
```

Now use chmod command to make the file executable:

```bash
sudo chmod 755 /etc/rc.local
```

### Sources

Inspired and based on:

- [IPv6](https://itsfoss.com/disable-ipv6-ubuntu-linux/)
- [qemu-guest-agent](https://pve.proxmox.com/wiki/Qemu-guest-agent)
