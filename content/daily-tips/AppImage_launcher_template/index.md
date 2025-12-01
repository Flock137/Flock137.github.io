---
title: "How do you make a launcher for an AppImage?"
date: 2025-12-01
draft: true
ShowToc: true
tags: 
    - daily-tech-tips
    - Linux
---

# Introduction 

For this purpose you actually have [AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher) for the convenience,
or the apps would actually self-generate this for you, but this doesn't always happen.
However, if you do mind the bloatness of said app (300 MB-ish), or the devs just don't have the launcher ready, then you may consider making the launcher yourself, by hand. 


# AppImage Launcher Template (`AppName.desktop`)

This is my standard template for almost every AppImage, and I will explain how it work: 

```
[Desktop Entry]
Version=1.0
Type=Application
Name=Application Name
GenericName=App Type
Categories=Utility;
Comment=Brief description of the application
Exec=/path/to/application.AppImage
Icon=/path/to/icon.png
Terminal=false
StartupNotify=true
```

- `Version` - The app version. If you got too lazy to find which version it is, you may leave it as 1.0.0
- `Type` - Just leave it as "Application"
- `Name` - Write your App name here, you can use any name you like. 
- `GenericName` - Categories name for human-view (Web Browser, Utilities, System, etc.)
- `Categories` - Categories name for machine, similar to that of GenericName, but you can't have space or special character inside 
- `Comment` - A brief description of what your app does 
- `Exec` - Path to the app's executable
- `Icon` - Path to the app's icon (sometimes, the app is able to display the icon by itself, although you didn't set the icon path)
- `Terminal` - Whether to invoke the terminal when open the app. Highly recommend to leave it as `false`, unless for specific reasons
- `StartupNotify` - Would the app notify you when it launch? This one is depends on your need. By default it is `true`



