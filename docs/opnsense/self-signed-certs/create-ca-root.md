# **Add CA Root in OPNsense**
>
> OPNsense version: 25.1.2

This guide will walk you through creating a **Certificate Authority (CA)** in OPNsense. A CA is necessary to issue and manage certificates for securing your network services (e.g., HTTPS, VPNs).

---

## **1. Create a CA Root**

1. Log in to your OPNsense web interface.
2. Navigate to **System > Trust > Authorities**.
3. Click **Add** to create a new CA.
4. Fill in the following fields:
    - **Method**: Select **Create an internal Certificate Authority**.
    - **Descriptive**: `My Local CA` (or any name you prefer).
    - **Digest Algorithm**: Choose `SHA256`.
    - **Key type:** `RSA-2048`
    - **Issuer:** `Self signed`
    - **Lifetime**: Set the validity period (e.g., `3650` days for 10
    years).
    - **Country Code**: Select your country.
    - **Organization:** `My Local CA` (or any name you prefer).
    - **Common Name**: `My Local CA` (or any name you prefer).
5. Click **Save** to create the CA.

## **2. Export the CA Root Certificate from OPNsense**

1. Log in to your OPNsense web interface.
2. Navigate to **System > Trust > Authorities**.
3. Find your CA in the list and click the **Export** button.
4. Download the `.crt` file (e.g., `My_Local_CA.crt`).

## **3. Add CA Root to devices**

### **For Windows 10/11**

1. **Open the Certificate Manager**:
    - Press `Win + R`, type `certmgr.msc`, and press **Enter**.
2. **Import the CA Certificate**:
    - In the left pane, expand **Trusted Root Certification Authorities**.
    - Right-click on **Certificates** and select **All Tasks > Import**.
3. **Follow the Certificate Import Wizard**:
    - Click **Next**.
    - Browse to the downloaded `.crt` file (e.g., `My_Local_CA.crt`) and select it.
    - Click **Next**.
    - Ensure the certificate is placed in the **Trusted Root Certification Authorities** store.
    - Click **Next** and then **Finish**.
4. **Verify the Installation**:
    - In the **Certificates** folder under **Trusted Root Certification Authorities**, look for your CA (e.g., `My Local CA`).

### **For Android 10 and Above**

1. **Transfer the CA Certificate to Your Device**:
    - Copy the `.crt` file to your Android device (e.g., via USB, email, or cloud storage).
2. **Install the CA Certificate**:
    - Open the **Settings** app.
    - Go to **Security > Encryption & credentials**.
    - Select **Install a certificate > CA certificate**.
    - Tap **Install anyway** (if prompted with a warning).
    - Browse to the `.crt` file and select it.
    - Confirm the installation by giving the certificate a name (e.g., `My Local CA`).
3. **Verify the Installation**:
    - Go to **Settings > Security > Encryption & credentials > Trusted credentials**.
    - Under the **User** tab, you should see your CA listed.
