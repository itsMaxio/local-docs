# Installation
 Run the install-script by running this command from CLI on the system:

```bash
curl -L https://bit.ly/glances | /bin/bash
```

After installation start the web interface by typing:

```bash
glances -w
```

Create a auto-start service file by typing:

```bash
sudo nano /etc/systemd/system/glances.service
```

Nano will start, paste in the following:

```ini
[Unit]
Description=Glances
After=network.target

[Service]
ExecStart=/usr/local/bin/glances -w
Restart=on-abort
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Press `CTRL+X` to exit and `Y` to save. Press Enter to Confirm file/location.
Next step is to create a symlink by typing:

```bash
sudo systemctl enable glances.service
```

The respons should be Created symlink `/etc/systemd/system/multi-user.target.wants/glances.service` → `/etc/systemd/system/glances.service`.

Start the service with:

```bash
sudo systemctl start glances.service
```

Done.

## Sources
- https://flemmingss.com/glances-installation-and-autostarting-on-linux/
- https://github.com/nicolargo/glances/blob/master/README.rst
- https://github.com/nicolargo/glances/wiki/Start-Glances-through-Systemd
