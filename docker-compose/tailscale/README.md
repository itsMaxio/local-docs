# Tailscale configuration with internal LAN and DNS

Simple Tailscale configuration with internal LAN access and DNS (PiHole, NPM).

## Before start

Steps before running

1. Copy [docker compose](docker-compose.example.yaml) into `docker-compose.yaml` file or copy directly into Portainer Stack
2. Change `volume` location to correct
3. Go to [admin console](https://login.tailscale.com/admin/settings/keys) in Tailscale and generate auth key

## First run

First run steps

1. Run your stack via command or Portainer
```bash
docker compose up
```
2. To log into Tailscale run the command in the container or via `Exec Console` (ash) inside Portainer (copy without `sudo docker exec tailscale`)

```bash
sudo docker exec tailscale tailscale up --auth-key=<PUT YOUR AUTH KEY HERE>
```

3. Disable `key expire` in `Admin Console`

## How to setup LAN

To configure LAN access you have to enable subnet in container via command or `Exec Console` (ash) inside Portainer (copy without `sudo docker exec tailscale`)

```bash
sudo docker exec tailscale tailscale up --accept-dns=false --advertise-routes=192.168.1.0/24
```

then click on the 3 dots next to your machine settings in `Admin Console` and `Edit route settings` and enable your Subnet

## How to setup DNS

Copy the `tailscale` ip address in your `Machines` tab then go to `DNS` settings in `Admin Console` and create custom `Nameservers` with the address you copied then click `Override local DNS` and you are done

Go to DNS tab in PiHole settings and change `Interface settings` to `Permit all origins`

## Sources

Inspired and based on [Access a Pi-hole from anywhere](https://tailscale.com/kb/1114/pi-hole/)