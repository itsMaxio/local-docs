# Copy key from Windows to Linux

Once you have your SSH keys generated, the following command will copy them to the target host. It will also create the ~/.ssh/ directory and the authorized_keys file if they do not exist.

Run this oneliner from a powershell prompt.

```bash
cat .\<key-name>.pub | ssh <username>@<ip> "mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"
```

## Sources

Inspired and based [on](https://codingpackets.com/blog/copy-ssh-keys-to-linux-host-from-windows-10/).
