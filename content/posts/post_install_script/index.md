---
title: "Setting up a stable Arch-based Penetration Testing environment"
date: 2025-12-01
draft: true
ShowToc: true
tags: 
    - EndeavourOS
    - Arch
    - Linux
    - VM
    - Red-Team
---

# Intro 
This is actually my thought process of making this script https://github.com/Flock137/EOSxBlackArch, where I put the BlackArch repo on top of EndeavourOS for a quick Arch pentest environment, since BlackArch is a bit of a hassle for installing quickly. 

I hope it would help you in the case you wanna make an automation script yourself someday.

# First and foremost
Install EndeavourOS. We will port our BlackArch repo into right after the former's installation finish. 

# Port the BlackArch repo
Please refer to this tutorial for your reference: https://blackarch.org/downloads.html#install-repo (Section: **Installing on top of ArchLinux**).

The example below should give you a preview on what you need to do this step.

```
# Run https://blackarch.org/strap.sh as root and follow the instructions.

curl -O https://blackarch.org/strap.sh

# Verify the SHA1 sum

echo bdbaf7ecd039859160849a46694fe4921371e5b1 strap.sh | sha1sum -c

# Set execute bit

chmod +x strap.sh

# Run strap.sh

sudo ./strap.sh

# Enable multilib following https://wiki.archlinux.org/index.php/Official_repositories#Enabling_multilib and run:

sudo pacman -Syu
```

After the `sudo pacman -Syu`, most of the barebone, necessary security tools will be automatically installed for you


## Other (useful) commands
```
# To list all of the available tools, run

sudo pacman -Sgg | grep blackarch | cut -d' ' -f2 | sort -u

# To install a category of tools, run

sudo pacman -S blackarch-<category>

# To see the blackarch categories, run

sudo pacman -Sg | grep blackarch

# To search for a specific package, run

pacman -Ss <package_name>

# Note - it maybe be necessary to overwrite certain packages when installing blackarch tools. If  
# you experience "failed to commit transaction" errors, use the --needed and --overwrite switches  
# For example:

sudo pacman -Syyu --needed --overwrite='*' <wanted-package>
```


# Other manually installed apps
- cutter
- burpsuite 
- ghidra 
- impacket-ba (you will call the script up by its name, e.g. `rpcdump.py`)
- stegsolve
- steghide
- audacity 
- bloodhound 
- python-uncompyle6
- villain (maybe it got installed already? Gotta make an exception script for this situation. Nevermind, just put the flag `--needed` after each `pacman -S`)
- rekall
- autopsy
- vim 
- (input more packages that you like to use here)

# Custom zsh-shell 
## First

```
sudo pacman -S zsh 
```

## Install oh-my-zsh 
Reference: https://ohmyz.sh/#install

```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

or: 

```
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
```

After ohmyzsh offer to change shell, type `y`. 
Manually: Log out and log back in so the change take effect. 
But the script will go on after this and prompt user to log out or reboot at the end.

## Install autosugestions and syntax highlighting
Reference: https://gist.github.com/n1snt/454b879b8f0b7995740ae04c5fb5b7df

- autosuggesions plugin: 
`git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions`

- zsh-syntax-highlighting plugin    
`git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting`

(I don't recommend installing too much plugins, though. It will slow down your terminal startup.)

Open `~/.zshrc`:
```
vim ~/.zshrc
```

Find the line that say: `plugin=(git)
`
Add your plugins inside the parenthesis, like this: 
```
plugin=(git
		zsh-autosuggestions
		zsh-syntax-highlighting)
```

Then exit the terminal for change to take effect
## Custom the terminal handle
_The line that have your name and stuffs like that, y'know_

I personally use the [heapbytes](https://github.com/heapbytes/heapbytes-zsh), so my script will install this theme, as well.

Heapbytes theme feature: 

- Prints the current working directory
- Prints the tun0 IP if connected to a VPN
- Prints the wlan0 IP if you aren't connected to any VPN. (change the module name in `.zsh-theme` according to your wifi module)
- Git info

Install https://github.com/heapbytes/heapbytes-zsh/raw/refs/heads/main/heapbytes.zsh-theme to $ZSH_CUSTOM/themes/

In `~/zshrc`: 
```
ZSH_THEME="heapbytes"
```
save and exit terminal for the change to take effect.

# (Unrelated) notes 
- If an encrypted `.zip` failed to extract while you are at it, chances are you were typing in the wrong password



