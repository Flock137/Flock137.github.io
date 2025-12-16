---
title: "How to see differences between files"
date: 2025-12-18
draft: false
ShowToc: true
tags: 
    - daily-tech-tips
    - Linux
---

In the case like this: 
```
warning: /etc/bluetooth/main.conf installed as /etc/bluetooth/main.conf.pacnew
```

You may like to know what is the difference between these two, concisely. We use the command `diff`, a basic utility of Linux

An example: 
```
diff /etc/bluetooth/main.conf /etc/bluetooth/main.conf.pacnew
```

Output: 
```
264a265,269
> # This enables the GATT client functionally, so it can be disabled in system
> # which can only operate as a peripheral.
> # Defaults to 'true'.
> #Client = true
> 
311,315d315
< # This enables the GATT client functionally, so it can be disabled in system
< # which can only operate as a peripheral.
< # Defaults to 'true'.
< #Client = true
< 
362c362
< #AutoEnable=false
---
> #AutoEnable=true
```

`>` indicate what appear in the latter file and `<` is pointing toward the former file. 
