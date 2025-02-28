# Enabling Communication Between LAN and IOT VLANs for Chromecast on OPNsense
>
> OPNsense version: 25.1.2

This guide will help you set up communication between a LAN VLAN and an IOT VLAN containing a Chromecast device on OPNsense. The configuration involves installing the `MDNS Repeater` plugin and creating appropriate firewall rules.

---

## Step 1: Install the MDNS Repeater Plugin

1. Log in to your OPNsense dashboard.
2. Navigate to **System > Firmware > Plugins**.
3. Search for the `os-mdns-repeater` plugin in the list.
4. Click **Install** to add the MDNS Repeater plugin to your system.

### What is the MDNS Repeater?

The MDNS Repeater makes it possible for multicast DNS (mDNS) communication to work across different VLANs. This is necessary for services like Chromecast that rely on mDNS for device discovery and communication.

---

## Step 2: Configure the MDNS Repeater Plugin

1. Navigate to **Services > MDNS Repeater** in the OPNsense dashboard.
2. Under **Listen Interfaces**, select both your **IOT VLAN** and **LAN VLAN**.
3. Click **Save** to apply the configuration.

---

## Step 3: Create an Alias for Required Ports

1. Go to **Firewall > Aliases**.
2. Click **+ Add** to create a new alias.
3. Set the following:
   - **Name**: `Chromecast_Ports`
   - **Type**: **Port**
   - **Ports**: `1900`, `5353`, `8008`, `8009`, `8443`, `8080`
   - Add each port to the alias list.
4. Save the alias and apply the changes.

---

## Step 4: Create Firewall Rules on VLAN Interfaces

### Rule on IoT VLAN Interface

1. Navigate to **Firewall > Rules > [IoT VLAN]**.
2. Click **+ Add** to create a new rule.
3. Configure the rule as follows:
   - **Action**: Pass
   - **Protocol**: **TCP/UDP**
   - **Source**: **IoT VLAN net**
   - **Destination**: **LAN net**
   - **Destination Port Range**: Select the alias `Chromecast_Ports` created earlier.
4. Add a meaningful **Description**, e.g., `Allow IoT to LAN for Chromecast`.
5. Click **Save** and **Apply Changes**.

### Rule on LAN Interface

1. Navigate to **Firewall > Rules > [LAN]**.
2. Click **+ Add** to create a new rule.
3. Configure the rule as follows:
   - **Action**: Pass
   - **Protocol**: **TCP/UDP**
   - **Source**: **LAN net**
   - **Destination**: **IoT VLAN net**
   - **Destination Port Range**: Select the alias `Chromecast_Ports` created earlier.
4. Add a meaningful **Description**, e.g., `Allow LAN to IoT for Chromecast`.
5. Click **Save** and **Apply Changes**.

---

## Step 5: Verify Connectivity

1. Test communication between devices on the LAN VLAN and the Chromecast in the IOT VLAN.
2. Ensure that the Chromecast device is discoverable and working as expected.

---

You have now successfully configured OPNsense to enable communication between the LAN VLAN and IOT VLAN for Chromecast. 🎉
