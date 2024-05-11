# Docker Network Setup

This guide explains how to create a network in Docker using the Docker CLI.

## Creating a Docker Network

To create a Docker network, follow these steps:

1. Create a Docker network:

```bash
sudo docker network create --subnet=192.168.100.0/24 --gateway=192.168.100.1 mynetwork
```

Replace 192.168.100.0/24 with your desired subnet and 192.168.100.1 with your desired gateway IP.
2. Verify the network creation:

```bash
sudo docker network ls
```

This command will list all the Docker networks, and you should see your newly created network (mynetwork in this example).
3. Inspect the network:

```bash
sudo docker network inspect mynetwork
```
