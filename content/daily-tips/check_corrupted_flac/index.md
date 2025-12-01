---
title: "Checking whether media files are (partly) corrupted using ffmpeg"
date: 2025-12-01
draft: true
ShowToc: true
tags: 
    - daily-tech-tips
    - ffmpeg
    - media
---














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

