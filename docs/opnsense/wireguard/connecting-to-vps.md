# Configure WireGuard with OPNsense and a VPS
> OPNsense version: 25.1.2

This guide will help you configure WireGuard on an OPNsense firewall as a peer and a VPS as the server. The goal is to allow the VPS to access an server (`10.10.20.2/24`) behind OPNsense.

---

## **1. Configure WireGuard on OPNsense**

### **1.1. Generate WireGuard Keys**

Run the following command on your **OPNsense shell (SSH or console):**

```bash
wg genkey | tee privatekey | wg pubkey > publickey
```

To view the keys:

```bash
cat privatekey
```

```bash
cat publickey
```

Save the **public key** for the VPS configuration.

---

### **1.2. Create WireGuard Instance on OPNsense**

1. Navigate to **VPN** > **WireGuard**.
2. Go to the **Local** tab and click **Add**.
3. Configure as follows:
   - **Enabled:** ✅
   - **Name:** `VPS_Instance`
   - **Private Key:** `<OPNSENSE_PRIVATE_KEY>` (from `privatekey`)
   - **Public Key:** `<OPNSENSE_PUBLIC_KEY>` (from `publickey`)
   - **Tunnel Address:** `10.10.10.2/24`
   - Click **Save** and **Apply Changes**.

---

### **1.3. Add Peer (your VPS)**

1. Go to the **Peers** tab and click **Add**.
2. Configure as follows:
   - **Enabled:** ✅
   - **Name:** `VPS`
   - **Public Key:** `<VPS_PUBLIC_KEY>` (from the VPS generation below)
   - **Allowed IPs:** `10.10.10.1/32, 10.10.10.0/24`
   - **Endpoint Address:** `<VPS_PUBLIC_IP>`
   - **Endpoint Port:** `51820`
   - **Persistent Keepalive:** `25`
   - Click **Save** and **Apply Changes**.

---

## **2. Configure WireGuard on VPS**

### **2.1. Install WireGuard on VPS**

```bash
sudo apt update && sudo apt install wireguard -y
```

---

### **2.2. Generate WireGuard Keys on VPS**

```bash
wg genkey | tee privatekey | wg pubkey > publickey
```

Save the **public key** for the OPNsense peer configuration.

---

### **2.3. Configure WireGuard on VPS**

Edit the WireGuard config file:

```bash
sudo nano /etc/wireguard/wg0.conf
```

Add the following:

```conf
[Interface]
PrivateKey = <VPS_PRIVATE_KEY> #This is private key of VPS
Address = 10.10.10.1/24
ListenPort = 51820

[Peer]
PublicKey = <OPNSENSE_PUBLIC_KEY> #This is public key of OPNsense
AllowedIPs = 10.10.10.2/32, 10.10.20.0/24
#AllowedIPs = 10.10.10.2/32, 10.10.20.0/24, 10.10.30.0/24
#If you want you can add more subnets then VPS will be able to communicate with them. Of course you have to change the rules in OPNsense
PersistentKeepalive = 25
```

---

### **2.4. Start WireGuard and enable on boot**

```bash
sudo systemctl start wg-quick@wg0
sudo systemctl enable wg-quick@wg0
```

---

## **3. Configure Firewall Rules on OPNsense**

1. Go to **Firewall** > **Rules** > **WireGuard**.
2. Click **Add** and configure:
   - **Action:** Pass
   - **Interface:** WireGuard
   - **Protocol:** Any
   - **Source:** WireGuard Net
   - **Destination:** `<WHERE YOU WANT>`
   - Click **Save** and **Apply Changes**.

---

## **4. Allow access WireGuard Port on VPS Firewall**

If your VPS has a firewall (UFW or cloud provider firewall), allow the WireGuard port:

### **UFW Example**

```bash
sudo ufw allow 51820/udp
```

### **Oracle Cloud Example**

1. Log into your **Oracle Cloud Console**.
2. Navigate to **Networking** > **Virtual Cloud Networks (VCN)**.
3. Select your **VCN** and go to the **Security Lists**.
4. Click on the **default security list**.
5. Click **Add Ingress Rule** and configure:
   - **Source:** `0.0.0.0/0`
   - **Protocol:** UDP
   - **Port Range:** `51820`
   - Click **Save Changes**.

---

## **5. Enable IP Forwarding on VPS**

To allow the VPS to route traffic to the Ubuntu server behind OPNsense, enable IP forwarding:

```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

## **6. Test the Connection**

1. On OPNsense, check the WireGuard status:

   ```bash
   wg show
   ```

2. From the VPS, ping the OPNsense WireGuard IP:

   ```bash
   ping 10.10.10.2
   ```

3. From the VPS, ping the another subnet behind OPNsense:

   ```bash
   ping 10.10.20.2
   ```

4. From the example server behind OPNsense, ping the VPS:

   ```bash
   ping 10.10.10.1
   ```

If you see a **handshake** in `wg show` and successful pings, the connection is working!
