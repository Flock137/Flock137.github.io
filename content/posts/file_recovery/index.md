---
title: How to recover deleted files on usb or memory card
date: 2026-02-21
draft: false
ShowToc: true
tags: 
    - Linux
    - Windows
    - Memory
    - Forensics
---

# TLDR
Stop using both the usb and memory card at once. Else, it will be next to impossible to recover anything back, since the data cells got overwritten, instead of just being "unlisted".

On Window (Linux), you can just install Recuva (extundelete or fatcat) for free and point the app to your usb or memory card, you're welcome. However, I would still prefer a more sure-fire way to preserve my data, hence the blog.

# Introduction 
Dear my future-self and future-comers, I hope you won't need this. But, if you do, this guide has your back. 

Godspeed!

# Before we begin...
Note that, while you are messing with your files in either Linux and Windows, anything deleted on detachable memory will be stored in their respective trash bins. 

On Windows, that will be in your usual trash bin. 

On Linux, however, to make sure people don't mess things up by accident, it will be stored in a hidden folder that look similar to `.Trash-1000` within that detachable device. In order to see the folder, you need to enable Hidden Files in your Files Manager. And, for deleting it, you can not use the GUI, but instead, open the Terminal within that USB and `sudo rm- rf .Trash-1000` to delete permanently (Yes, I wish there is a less destructive command, like `rm -rd`, but it is really the only command you can use...). 
***Please only attempt this when you know exactly what you are doing.***


# Recovery steps

First, stop using your cards/usb (from now on, I will only mention the usb, but the steps for cards are still identical) at once, to minimize any writing activity on them. Then set permission to read-only.

Next, we need to image the drive.

## On Linux
Use ddrescue OR dd (it's on linux by default, but I recommend using ddrescue because it's more straightforward)

```
sudo ddrescue /dev/sdX usb_image.img usb_image.log
```

Or: 

```
sudo dd if=/dev/sdX of=usb_image.img bs=4M status=progress conv=noerror,sync
```

*change the sdX by your actual drive listed by `lsblk`

Now, try either on the image file that you just create:
- testdisk: When you want to preserve file names.
- photorec: When testdisk does not work, and you don't mind file names are messed up.
- If you can determine that your disks are either any `FAT` or any `ext`, try accordingly: extundelete or fatcat

## Windows
Download FTK Imager (proprietary, but free for personal use, you just need to fill in a form) for imaging disk: 
```
File -> Create Disk Image -> Physical Drive -> select your USB -> Output as raw (.dd or .img)
```

After you have the image, use either Autopsy (the proper DFIR way) or Recuva (when you don't really need to know how to use Autopsy)

# Conclusion
The tutorial did not cover any edge cases... I really hope you don't have to encounter them. 

Good luck!

