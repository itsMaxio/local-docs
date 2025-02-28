# **Create Certificates in OPNsense**
>
> OPNsense version: 25.1.2

This guide explains how to create **certificates** in OPNsense using a **Certificate Authority (CA)**. These certificates can be used to secure services like HTTPS, VPNs, or internal applications.

---

## **1. Prerequisites**

- A **Certificate Authority (CA)** must already be created in OPNsense. If you don't have one, follow the CA Root creation guide first.

---

## **2. Create a Certificate**

1. **Log in to OPNsense**:
    - Access your OPNsense web interface.
2. **Navigate to Certificates**:
    - Go to **System > Trust > Certificates**.
3. **Add a New Certificate**:
    - Click the **Add** button to create a new certificate.
4. **Configure the Certificate**:
    - Fill in the following fields:
        - **Method**: Select **Create an internal Certificate**.
        - **Descriptive name**: Enter a name for the certificate (e.g., `Web Server Cert`).
        - **Type**: Choose **Server Certificate** (for HTTPS).
        - **Issuer**: Select the CA you created earlier (e.g., `My Local CA`).
        - **Lifetime**: Set the validity period (e.g., `365` days for 1 year).
        - **Country Code**: Select your country.
        - **Common Name**: Enter the primary domain or hostname (e.g., `home.local`).
5. **Add Subject Alternative Names (SANs)**:
    - If you need a **wildcard certificate** or want to include additional domains:
        - Scroll down to the **Alternative Names** section.
        - In the **DNS domain names** box write your domains

   ```
   home.local
         *.home.local
         ```

6. **Save the Certificate**:
    - Click **Save** to create the certificate.

## **3. Export the Certificate (Optional)**

If you need to use the certificate on other devices (e.g., a web server or VPN client):
7. Go to **System > Trust > Certificates**.
8. Find your certificate in the list and click the **Export** button.
9. Download the `.pem` (certificate) and `.key` (private key) files.
