# Relocating the Docker root directory

If the file space in the Docker root directory is not adequate, you must relocate the directory.

# Procedure

To relocate the Docker root directory, complete the following steps as root or a user with “sudo all” authority:

1. Stop the Docker services:

```bash
sudo systemctl stop docker
```

```bash
sudo systemctl stop docker.socket
```

```bash
sudo systemctl stop containerd
```

2. Create the necessary directory structure into which to move Docker root by running the following command. This directory structure must reside on a file system with at least 50 GB free disk space. Significantly more disk space might be required depending on your daily ingestion volumes and data retention policy.

```bash
sudo mkdir -p /new_dir_structure
```

3. Move Docker root to the new directory structure:

```bash
sudo mv /var/lib/docker /new_dir_structure
```

4. Edit the file `/etc/docker/daemon.json`. If the file does not exist, create the file by running the following command:

```bash
sudo nano /etc/docker/daemon.json
```

Add the following information to this file:

```json
{
  "data-root": "/new_dir_structure/docker"
}
```

5. After the `/etc/docker/daemon.json` file is saved and closed, restart the Docker services:

```bash
sudo systemctl start docker
```

6. After you run the command, all Docker services through dependency management will restart.
Validate the new Docker root location:

```bash
sudo docker info -f '{{ .DockerRootDir}}'
```

## Sources

Inspired and based on [Relocating the Docker root directory by IBM](https://www.ibm.com/docs/en/z-logdata-analytics/5.1.0?topic=compose-relocating-docker-root-directory)
