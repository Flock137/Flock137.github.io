---
title: "Revive FlareVM Network Connection (VirtualBox)"
date: 2025-11-09
draft: true
ShowToc: true
tags: 
    - FlareVM
    - Malware Analysis
    - Windows
---

# Introduction 
Normally, installing a FlareVM won't mutate your network connection. However, for some reason, I wasn't able to access network inside the VM. This could have caused by one or a couple of reasons: 
- Non-fatal errors occured during installation (I was supposed to look at the screen during all process, but it took 6h to finish...)
- The recovery function of Windows got forced shut down to fulfill installation prerequisites, so it can not intervene and autofix the network issues 
- A driver "Other" was spotted to be missing after FlareVM completely finish its installation

# VirtualBox network setting walkthrough
