# How to change Default Subnet

This guide explains how to change default subnet for docker.

## Changing default subnet

1. Edit file `/etc/docker/daemon.json`:

```bash
sudo nano /etc/docker/daemon.json
```

```yaml
{
  "bip": "10.10.1.1/24",
  "default-address-pools": [
    { "base": "10.20.0.0/16", "size": 24 }
  ]
}
```

>The field bip (Bridge IP) defines the IP range that network interface docker0 can use. The example reserves IP range 10.10.1.1/24 to the interface. Beware, the range must end with .1, otherwise docker won’t start.

>The field default-address-pools defines the IP range of network interfaces. The example reserves IP range 10.20.1.0/24.

2. Restart docker:

```bash
sudo systemctl restart docker
```

3. Check that the IPs changed:

```bash
sudo docker network inspect bridge | grep Subnet
```

## Sources

<https://docs.cyberwatch.fr/help/en/general_administration_software/docker_configuration/change_docker_IP_range/>
