---
title: "Checking whether media files are (partly) corrupted using ffmpeg"
date: 2025-12-01
draft: false
ShowToc: true
tags: 
    - daily-tech-tips
    - ffmpeg
    - media
---

# Intro
Normally, you wouldn't need to this kind of check, even in the case of serious corruption, the file just won't be able to play and that's it. 

However, if you self-host and streaming your own music or media like myself, you might notice that some of your music might refuse to play while it plays normally on your music player (and it might even make your PC heats up). 

This is due to partial corruption in your file. Normally, when you play the file in your system, it will be able to automatically "fill in the blank" of the corruption bits. But in self-hosting or streaming scenarios, these services won't be able to pick that up and recover your file (well, to be fair, it did try, but can't since this is a computing intensive task), hence the reason it doesn't play (and also heats your CPU up whilst trying).

# To check whether there is corruption...

Open up your favourite text editor and store this script below in a file named `music_check`:
```
# Find all FLAC files and test them
find ~/Music -name "*.flac" -type f | while read -r file; do
    echo "Testing: $file"
    if ! ffmpeg -v error -i "$file" -f null - 2>&1 | grep -q "error\|invalid"; then
        echo "✓ OK"
    else
        echo "✗ CORRUPTED: $file"
    fi
done
```

Then, type in the terminal `chmod u+x music_check` and run it using command `./music_check`, it will print out for your which files are corrupted. 

After you find out which one is corrupted, I recommend you to just re-download the file instead of fixing the corruption. 
