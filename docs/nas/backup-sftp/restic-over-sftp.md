# Restic over SFTP with TrueNAS SCALE

This guide explains how to configure TrueNAS SCALE to provide SFTP-based backups for Restic.  
The setup isolates users into their own datasets with `ChrootDirectory` for security and ensures that each user has their own backup directory.

## 1. Create main backup dataset

1. In the **TrueNAS SCALE GUI**, go to **Datasets**
2. Create a dataset named `backups`
3. Inside `backups`, create another dataset, for example `restic`
4. Set the **permissions** of the `restic` dataset to:
   - **Owner (User)**: `root`
   - **Owner (Group)**: `root`
   - **Mode**: `755`

This dataset will serve as the `ChrootDirectory` for all SFTP users.

## 2. Create user datasets

1. For every system or client that will back up with Restic, create a new dataset under `backups/restic`
   > Example: `backup-debian`
2. The dataset **name must match the future username** (important for SFTP chroot to work correctly)
3. Leave default ownership and permissions at this stage, as they will be changed automatically when the user is created

## 3. Create shared SFTP group

1. Navigate to **Credentials -> Groups**
2. Create a new group, e.g. `backup-sftp`
3. Set a unique **GID** (for example `4000`)
4. Do not assign any privileges to this group. It will only be used for SSH restrictions

## 4. Create per-user groups and accounts

### 4.1 Create user group

1. Create a group with the **same name** as the **dataset**.  
   > Example: `backup-debian` (with GID e.g. `4001`).

### 4.2 Create user

1. Navigate to **Credentials -> Users** and create a new user
2. Username **must match** the dataset and group (e.g. `backup-debian`)
3. Configure the following options:
   - **Disable Password**: `ON`  
   - **UID**: `4000` (Same as primary group GID)
   - **Auxiliary Groups**: select the `backup-sftp` group created in **step 3**
   - **Create New Primary Group**: `OFF`, select the group created in **4.1**
   - **Home Directory**: set to the user dataset (e.g. `/mnt/POOL/backups/restic/backup-debian`)
   - **Home Directory Permissions**: `700` (User: Read, Write, Execute; no access for others)
   - **Create Home Directory**: `OFF`
   - **Authorized Keys**: paste the user’s public SSH key here
   - **Shell**: `nologin`
   - **SMB User**: `OFF`

After saving, TrueNAS will automatically adjust ownership of the dataset to match the user and group.

## 5. Configure SSH service for SFTP chroot

1. Go to **System -> Services -> SSH**.
2. Enable the service and open **Advanced Settings**.
3. In **Auxiliary Parameters**, add the following configuration:

```bash
Match Group backup-sftp
    ChrootDirectory /mnt/POOL/backups/restic
    ForceCommand internal-sftp -d %u
```
