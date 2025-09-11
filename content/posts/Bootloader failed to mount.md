---
title: "How did I repair an (Arch) Linux bootloader twice"
date: 2025-11-09
draft: false
ShowToc: true
tags: 
    - Arch
    - Linux
---

# Introduction: Updating BIOS, got Linux overwritten
After I updated my BIOS, it happened to auto turn on secure boot, bitlocker again and overwrite the bootloader on my Linux partition on a separated disk. 
Not to mention, I no longer see my `systemd` bootloader screen. 

## Disable bitlocker key 
To disable bitlocker key (not decrypt the whole drive), so the windows partition won't ask you bitlocker password over and over again when you dual-boot: 
```
manage-bde -off F:
```
Where `F:` is the letter disk you want the key to be disable. For me, I use `C:`.

## Secure boot
Enter the BIOS to turn off secure boot. The way you would enter the BIOS would be depend on your desktop model. 
On Google, search:"[Your desktop model] how to enter BIOS"

## Restart again 
After finish the two steps above, you need to enter the windows partition again and type in your bitlocker key, or if it doesn't ask, then nice! You're in! 

Let's check our Linux partition 

# Save Linux partition 
Since I can't see my usual bootloader screen shows up, the laptop just straight up boot into my Windows partition instead. When checking with BIOS, turns out, what used to be my Linux Boot is now called "Windows Boot Manager", that means the **Linux bootloader got rewritten**. In this case there's pretty much nothing you can do about it except for reinstallation. 

Lucky for me, when I was installing EndeavourOS, I have made a partition table in which I have separated `/` (root) with `/home`. It means that, none of my data got corrupted during the BIOS update, only the root partition was. Therefore, in my reinstallation, I only need to reformat my root and reinstall apps again, which luckily doesn't take long, with all data in `/home` perfectly intact after installation.

However, there's an issue with bootloader right after I did my second update on the system, and I got thrown to rescue mode. 


# Inside Rescue mode (systemd)
- Use `journalctl -xb`, read all the logs. You might like to do `arch-chroot` (It's a bit complicate, a tutorial might be written later)
- After `arch-chroot` failed, I use `lsblk -f`, to check the mount status, somehow the EFI partition failed to mount itself (it doesn't appear to be mounted anywhere, indicated by the table)
- Now, do `cat /etc/stab`, see if there is any: wrong UUID, unusual mount point, etc. In my case, the UUID of the bootloader was wrong (or perhaps outdated after update), that's why it failed to mount itself to the system
- Copy the UUID from `lsblk -f` and write it to `/etc/stab`, then reboot. 

If bootloader failing to mount itself is your only issue, you should be able to boot your system again. 

