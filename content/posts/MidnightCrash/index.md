---
title: Sherlock - MidnightCrash writeup
date: 2026-04-17
draft: false
showToc: true 
tags:
  - Forensics
  - Linux
---

## Forewords
Ah yes, finally, some Linux forensics tasks. Though, this one should have been on the difficulty level of easy, not medium (in my opinion of course, but don't listen to this linux addict ;))

The most difficult part of this sherlock, in my opinion, is to figure out which tool would you need to read the kdump file, and henceforth, how to use `crash`.

## Introduction and Scenario 
> A production server crashed unexpectedly and rebooted. The crash happened at a strange time, and we doubt it was a simple hardware fault. A kernel crash dump was captured. Your mission is to analyze it to find the real cause of the crash and determine if any other suspicious activity was present on the system.

Straightforward enough, the scenario tells us to analyze a kernel crash dump. 

Folder structure: 
```
❯ tree
.
├── ubuntu22.04-5.15.0-25-generic-202511032103.kdump
└── vmlinux-dbgsym
```

We have a kernel crash dump and an uncompressed kernel ELF binary with full debug symbols.

## Task list
1. What is the hostname of the crashed server?
2. What is the assigned IP address of the server at time of crash?
3. When did the server crash? (UTC)
4. The crash was triggered by a specific process. What was the PID of the active process that caused the panic?
5. Which command-line utility was leveraged by the previous process to trigger the crash?
6. What was the kernel's fatal panic bug message?
7. What is the absolute path of the malicious file that caused the kernel crash?
8. What is the name of the function at the top of the kernel's call stack at time of the crash?
9. This function belongs to a malicious kernel module. What is the base memory address of this module?
10. What is the function name in the malicious kernel module that performs cleanup?
11. Before the kernel panic, a suspicious process was running with sudo privileges, What was the process name?

## Set up 
You need a package namely `crash`. In Arch Linux specifically, you install it with `sudo pacman -S crash`. This binary would help you read the kernel crash dump. 

After having `crash` ready, use the command: 

```
crash vmlinux-dbgsym ubuntu22.04-5.15.0-25-generic-202511032103.kdump
```

Then you should be thrown into in interactive shell within `crash`, which should look like this: 

```
crash> 
```

## 1. Hostname of crashed server 

When `crash` greets you, it may give you something similar to this: 

```
      KERNEL: vmlinux-dbgsym  [TAINTED]         
    DUMPFILE: ubuntu22.04-5.15.0-25-generic-202511032103.kdump  [PARTIAL DUMP]
        CPUS: 2
        DATE: Tue Nov  4 09:03:29 +07 2025
      UPTIME: 00:38:58
LOAD AVERAGE: 0.15, 0.08, 0.12
       TASKS: 548
    NODENAME: ubuntu-2204
     RELEASE: 5.15.0-25-generic
     VERSION: #25-Ubuntu SMP Wed Mar 30 15:54:22 UTC 2022
     MACHINE: x86_64  (2687 Mhz)
      MEMORY: 2 GB
       PANIC: "Oops: 0002 [#1] SMP PTI" (check log for details)
         PID: 9236
     COMMAND: "cat"
        TASK: ffff8e0479346200  [THREAD_INFO: ffff8e0479346200]
         CPU: 0
       STATE: TASK_RUNNING (PANIC)
```

If not, you use the `sys` command inside the `crash` interactive shell. 

In here you can see that: 
- The kernel is tainted (got tampered with)
- This is only a partial dump, and that it might not provide you with full information (irrelevant to this particular case though)
- **Captured datetime** in UTC +7 (my timezone)
- Nodename, or **Hostname** `ubuntu-2204
- Kernel version (Release section)
- Architecture used, Memory 
- Panic occured at which **PID**, with **command executed that lead to the crash**
- State of task: Running, lead to the panic 

## 2. Assigned IP Adress 
Use the command `net` in the shell: 

```
   NET_DEVICE     NAME       IP ADDRESS(ES)
ffff8e040258e000  lo         127.0.0.1, ::1
ffff8e0431754000  ens33      192.168.1.135, fe80::7c3a:396b:d8a6:c8a2
```

It's the one start with 192.

## 3. When did server crash 
Convert the captured datetime in section 1 and convert that into UTC. So that would be: 
```
2025-11-04 02:03:29
```

## 4. PID that causes the panic 
Now, you use `bt`, this command would BackTrace the process that lead to the kernel panic. You should see the PID of 9236 in log from said command. 

```
PID: 9236     TASK: ffff8e0479346200  CPU: 0    COMMAND: "cat"
 #0 [ffff9a64c611fb60] machine_kexec at ffffffff85685e40
 #1 [ffff9a64c611fbc0] __crash_kexec at ffffffff8578cc22
 #2 [ffff9a64c611fc90] crash_kexec at ffffffff8578e3a8
 #3 [ffff9a64c611fca0] oops_end at ffffffff8563fa06
 #4 [ffff9a64c611fcc8] page_fault_oops at ffffffff85697a0e
 #5 [ffff9a64c611fd28] do_user_addr_fault at ffffffff856981c9
 #6 [ffff9a64c611fd80] exc_page_fault at ffffffff86348ec7
 #7 [ffff9a64c611fdb0] asm_exc_page_fault at ffffffff86400ace
    [exception RIP: core_helper_read+8]
    RIP: ffffffffc0a94008  RSP: ffff9a64c611fe60  RFLAGS: 00010246
    RAX: 0000000000000000  RBX: ffff8e040e909780  RCX: ffff9a64c611fed0
    RDX: 0000000000020000  RSI: 00007fae8be3d000  RDI: ffff8e04107cb500
    RBP: ffff9a64c611fe80   R8: 0000000000000001   R9: ffff8e0419f77ab0
    R10: 0000000000020000  R11: 0000000000000000  R12: 0000000000000000
    R13: ffff8e04107cb500  R14: ffff9a64c611fed0  R15: 00007fae8be3d000
    ORIG_RAX: ffffffffffffffff  CS: 0010  SS: 0018
 #8 [ffff9a64c611fe68] proc_reg_read at ffffffff85a23a4a
 #9 [ffff9a64c611fe88] vfs_read at ffffffff85970f8f
#10 [ffff9a64c611fec8] ksys_read at ffffffff85973937
#11 [ffff9a64c611ff08] __x64_sys_read at ffffffff859739c9
#12 [ffff9a64c611ff18] do_syscall_64 at ffffffff863451bc
#13 [ffff9a64c611ff50] entry_SYSCALL_64_after_hwframe at ffffffff8640007c
    RIP: 00007fae8cd5c852  RSP: 00007fff5f513348  RFLAGS: 00000246
    RAX: ffffffffffffffda  RBX: 0000000000020000  RCX: 00007fae8cd5c852
    RDX: 0000000000020000  RSI: 00007fae8be3d000  RDI: 0000000000000003
    RBP: 00007fae8be3d000   R8: 00007fae8be3c010   R9: 00007fae8be3c010
    R10: 0000000000000022  R11: 0000000000000246  R12: 0000000000022000
    R13: 0000000000000003  R14: 0000000000020000  R15: 0000000000020000
    ORIG_RAX: 0000000000000000  CS: 0033  SS: 002b
```

## 5. Which command caused the crash? 
Utilize the same output from the above section, that'll be `cat`

## 6. Kernel fatal panic bug message 
type in `log` (actually, `log`, `sys` and `bt` should be what you output from crash, first and foremost)

Now, first, we would like to investigate the "Oops" incident from the greeting that we saw at section 1 (PANIC line). Notice the word "BUG"? Yes, that matters, because you would see it a couple of lines above the "Oops":

```
[ 2338.667536] BUG: kernel NULL pointer dereference, address: 0000000000000000
```

That was more straightforward than I thought, as I sort of speculated that we might have to chain a whole series of event to get to that point, but nope, it's a one liner. 

## 7 

To see that malicious file, remember the PID that we used in the previous section? We need to find what kind of process that caused that and how, so we would type in the shell: `files <pid>`

And the output would be: 
```
PID: 9236     TASK: ffff8e0479346200  CPU: 0    COMMAND: "cat"
ROOT: /    CWD: /root/module
 FD       FILE            DENTRY           INODE       TYPE PATH
  0 ffff8e040c25db00 ffff8e04072300c0 ffff8e0431368780 CHR  /dev/pts/1
  1 ffff8e040c25db00 ffff8e04072300c0 ffff8e0431368780 CHR  /dev/pts/1
  2 ffff8e040c25db00 ffff8e04072300c0 ffff8e0431368780 CHR  /dev/pts/1
  3 ffff8e04107cb500 ffff8e04072d8000 ffff8e0419f77ab0 REG  /proc/jiffies_ext
```

The last one look very abnormal, so there you go. 

## 8. Name of the function on top of the kernel stack
_when it crashed and burn :P_

Look at the `bt` output. See this line?

```
    [exception RIP: core_helper_read+8]
```

That's the answer. 

## 9.

To check the module that the system use, type in `mod`. You should see a `core_helper` process, match with our previous find in the last task, the base address should also be found there. 

## 10. What had performed the cleanup?

```
crash> sym -m <module_name>
```
This should lists all symbols exported by that module. And, yes, it's the one you found in previous task. 

Output: 
```
ffffffffc0a94000 MODULE START: core_helper
ffffffffc0a94000 (t) core_helper_read
ffffffffc0a94015 (t) core_helper_exit
ffffffffc0a94015 (T) cleanup_module
ffffffffc0a95024 (?) _note_9
ffffffffc0a9503c (?) _note_8
ffffffffc0a950e0 (?) proc_file_ops
ffffffffc0a96000 (?) __this_module
ffffffffc0a98000 MODULE END: core_helper
```

Well, well, well, don't you look at that juicy cleanup_module?

## 11. which did `sudo`?
Our very last task, and which also is the hardest task, in my humble opinion. 

For this, you would likely first type in `ps` and see which process abnormally uses the PID 0, but sadly, it's not that simple, as this command did not account for the parents-children relationship, and you only see swapper doing what it's supposed to do.

After digging a bit in the help page of ps (in the crash shell, you use `help ps`), I found two very interesting flags that I can use, either the flag `-k` or `-p`:
- `-k` will list you a process in timeline order. Which didn't help much.
- `-p` will show you processes, with their child-parent relationship. This is what I used to get the answer.
- (You can't mix and match these flags, sadly)

And I found this block: 
```
PID: 0        TASK: ffffffff8741b440  CPU: 0    COMMAND: "swapper/0"
 PID: 1        TASK: ffff8e04012dc980  CPU: 1    COMMAND: "systemd"
  PID: 3778     TASK: ffff8e041067b100  CPU: 1    COMMAND: "systemd"
   PID: 4486     TASK: ffff8e0410440000  CPU: 1    COMMAND: "gnome-terminal-"
    PID: 4504     TASK: ffff8e041044b100  CPU: 0    COMMAND: "bash"
     PID: 4552     TASK: ffff8e0410681880  CPU: 0    COMMAND: "sudo"
      PID: 4553     TASK: ffff8e040e884980  CPU: 1    COMMAND: "sudo"
       PID: 4554     TASK: ffff8e040e880000  CPU: 0    COMMAND: "su"
        PID: 4555     TASK: ffff8e0410680000  CPU: 0    COMMAND: "bash"
         PID: 8923     TASK: ffff8e04300e1880  CPU: 1    COMMAND: "sudo"
          PID: 8924     TASK: ffff8e04300e6200  CPU: 0    COMMAND: "sudo"
           PID: 8925     TASK: ffff8e041046b100  CPU: 0    COMMAND: "httpd-worker"
```

As a quite experienced linux user, this is, at first glance, looks very fishy. Also, when look at the process using its PID:

```
crash> files 8925
PID: 8925     TASK: ffff8e041046b100  CPU: 0    COMMAND: "httpd-worker"
ROOT: /    CWD: /root
 FD       FILE            DENTRY           INODE       TYPE PATH
  0 ffff8e040d2c0500 ffff8e040d826780 ffff8e0430529680 CHR  /dev/pts/2
  1 ffff8e040d2c0500 ffff8e040d826780 ffff8e0430529680 CHR  /dev/pts/2
  2 ffff8e040d2c0500 ffff8e040d826780 ffff8e0430529680 CHR  /dev/pts/2
```

Ain't that unusual. Base on the name alone, it has no business being at that location.

Well, anyway, that should be the answer to the last task. 

Note: `httpd-worker` is an Apache worker, and its parent should have been something of Apache or http, not child of sudo in user-typed terminal.








