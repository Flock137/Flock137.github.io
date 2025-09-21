---
title: "Recover corrupted USB in Linux terminal (required complete data wipe)"
date: 2025-09-11
draft: false
ShowToc: true
tags: 
    - Forensics
    - Tips
---

# Step 1
```
lsblk
```
The USB would likely to be something like `sda` or `sdb` (the same name with number is a partition). The easiest way to figure out which is your thumb drive is the size. 


# Step 2
If the system mount any of your partition, you need to unmount them first before wiping. 
```
# Replace sdX1 with your actual partition identifier (e.g., sdb1)
sudo umount /dev/sdX1
```

# Step 3
Use `wipefs` command to completely erase all partition tables and filesystem signatures from the drive. 
```
# REPLACE /dev/sdX WITH THE CORRECT DEVICE FROM STEP 1 (e.g., /dev/sdb)
sudo wipefs --all /dev/sdX
```

# Step 4
Use `fdisk` to create new structure for the drive 
```
# REPLACE /dev/sdX WITH THE CORRECT DEVICE (e.g., /dev/sdb)
sudo fdisk /dev/sdX
```
In `fdisk` prompt: 
- Type `g` and press Enter for GPT partition table (recomended). In the case that you know what you are doing and you need an MBR/DOS table, type `o`
- Type `n`, press Enter to create new partition
	- Partition number: type 1, you only need one partition for the thumb drive
	- First sector: Press Enter (default)
	- Last sector: Press Enter (default)
- Type `w` to write the partition table and exit. **You can not go back after doing this.**

Step 5: You need to have a file system for your USB to make it usable. Choose from one option: FAT32 or NTFS or ext4. FAT32 is more recommended because it can be use on any operating system, unless you have a specific use case in your mind. You may reformat it later with `Gparted`, if you change your mind, but make sure you make a back up of your data, if there is.

After you make your decision, execute one of the below: 
- FAT32: `sudo mkfs.vfat -n 'USBDRIVE' /dev/sdX1`
- NTFS: `sudo mkfs.ntfs -L 'USBDRIVE' /dev/sdX1`
- ext4: `sudo mkfs.ext4 -L 'USBDRIVE' /dev/sdX1`

Step 6: Safe ejection
Eject the drive and plug back in:
```
sudo eject /dev/sdX
```
It should now be automatically detected and mounted by your system as a perfectly clean, empty, and healthy USB drive.
