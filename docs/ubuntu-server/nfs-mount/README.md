# Install NFS Client

Ensure that the NFS client package is installed on your Ubuntu system. If not installed, you can install it using the following command:

```bash
sudo apt update
sudo apt install nfs-common
```

## Create mount location

You should create mount location

```bash
sudo mkdir /mnt/nfsshare
```

## Find NFS Share Details

You'll need to know the IP address or hostname of the NFS server and the path to the shared directory.

## Edit /etc/fstab

Open the `/etc/fstab` file in a text editor with root privileges. You can use nano or vim:

```bash
sudo nano /etc/fstab
```

## Add NFS Entry

Add a line at the end of the /etc/fstab file to define the NFS mount. The general format is:

```fstab
[NFS Server IP or hostname]:[NFS Share Path] [Local Mount Point] nfs [Options] 0 0
```

For example:

```fstab
192.168.1.100:/shared /mnt/nfsshare nfs defaults 0 0
```

Replace 192.168.1.100 with the IP address of your NFS server, /shared with the path to the shared directory on the NFS server, and /mnt/nfsshare with the local directory where you want to mount the NFS share.

## Save and Exit

Save the changes to the /etc/fstab file and exit the text editor.

## Mount the NFS Share

You can either reboot your system to automatically mount the NFS share during startup, or you can manually mount it without rebooting by running:

```bash
sudo mount -a
```

This command will read the /etc/fstab file and mount all entries that are configured to be mounted at boot time.
After these steps, the NFS share should be mounted on your Ubuntu system and will persist across reboots if configured correctly in `/etc/fstab`.
