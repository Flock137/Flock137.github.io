---
title: "How to download music from Youtube with yt-dlp (CLI)"
date: 2025-12-19
draft: false
ShowToc: true
tags: 
    - daily-tech-tips
    - Linux
    - yt-dlp
    - CLI
    - ffmpeg
---

## Downloading (yt-dlp)
You use this command: 
```
yt-dlp -f "bestvideo[height=2160]+bestaudio" -x --audio-format flac "VIDEO_URL"
```

In this command, I'm downloading from a 4K video (2160p), and I like my music to be in the `.flac` file. Feel free to change the quality and filetype into whatever you like. 

## Update metadata (ffmpeg)
Since the metadata won't come with the file by default, you may like to add it manually.

To do this, yt-dlp should also work. However, my preferred method is to use ffmpeg, instead:
```
ffmpeg -i "input.flac" \
    -metadata title="Song Title" \
    -metadata artist="Artist Name" \
    -metadata album="Album Name" \
    -metadata date="2024" \ 
    -metadata genre="Pop" \ 
    -codec copy "output.flac"
```

