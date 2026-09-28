---
title: HackTheBox's Cyber Apocalypse 2026 - Hardware 
date: 2026-09-28
draft: false
showToc: true 
tags:
  - Hardware
  - Write-up
---

Disclaimer: This write-up will be a bit brief. I will comeback to *actually* finish this write-up later. Ughh, should have written it when I have just finished:( 

## Cadence in the cord 
Description: 
With the Brine Signet shattered, every house hunts whatever might make its story law. Lady Seralyne — the Velvet Spider of Suncourt — sells what she claims is the dragon's true note: not the lost thing itself, only a counterfeit cadence arranged to be believed, and a wavering house is ready to buy it as proof its claim rings true. We cut one of her sendings from the wire first. Read the pleasant words; then attend to the silences between them, and expose the forgery she is truly selling.

For this challenge we will be provided a `capture.sr` file, which is a sigrok file (and, no, please don't extract the files, as it's not a normal archive). In order to read it, you need to install `sigrok`. 

(On Linux, your distro repository should have it already, if they don't, sigrok has an appimage if I'm not mistaken. )

After you done with that open up the file in sigrok. You should see the two channels named 0 and D1. And, by looking at it, I concluded that it was an UART signal. Use the "Decoder Selector" (the yellow-green standing wave icon) and pick UART. Then set TX as D1 and RX as 0. In order to know the exact baud rate, you need to measure the shortest pulse, by clicking on the blue flags icon and drag them around. Like this:

![[images/sigrok-blue-flags-icon.png]]

Then use the large value minus the small value, and compare that result (bit duration) to a [baud rate table](https://lucidar.me/en/serialib/most-used-baud-rates-table/), we got 9600 baud. Finally, optionally, set the data format to ASCII, to read the red herring (or hint) message:) (the [underscores](https://underscores.plus/) were my own notation for the space, initially)

```
To_the_buyer_who_paid_in_secrets:_what_follows_is_the_pleasant_tone_,
_the_goods_I_sell_in_day_light_and_never_miss. 
Lord Varo's debt, due at the second thaw, yours for a marriage you already
own. The Harlow inheritance, contested by a cousin whose witnesses I arranged. 
Take them and thank me. But what is written is worth nothing.
The dragon's true note does not Live in the words; it lives in the rests between them.
A long rest raises the mark to one, a short rest lets it fall to nothing;
count eight rests to every letter before the note will speak.
Read the silence, not the song, and pay.
```

Took me a good 2 hours of frustration to figure this out. 

You need to pay attention to what the last 3 sentences were implying at. The "rest" here means the signal line in-between the words' pulses. Like, the signal cover by the blue area below: 

![[images/rests.png]]

Long rest count as 1 and short rest count as 0. Collect all of the signal 1 and 0, we have a binary string: 

```
0111100101101111011101010010000001110010011001010110000101100100001000000111010001101000011001010010000001110011011010010110110001100101011011100110001101100101001000000111011101100101011011000110110000100000010010000101010001000010011110110111010001101000001100110101111101100110001100010111001001110011011101000101111101101101001101000111001001101011010111110111001000110001011011100110011101110011010111110111010001110010011101010011001101011111011000100011001101101110001100110011010001110100011010000101111101110100011010000011001101011111011101110011000001110010011001000111001101111101
```

Convert to text: 

```
you read the silence well 
HTB{th3_f1rst_m4rk_r1ngs_tru3_b3n34th_th3_w0rds}
```


## Thermal Receipt (Printer)
Description: 
Keir and his undercity runners recovered a forgotten Eastreach ration kiosk after Damas Marrowcairn sent clerks to strip the counting terminal and burn the paper ledger. They missed a small peripheral bolted beneath the counter. If the device still remembers the right transaction, it may hold the authorization token needed to move supplies through Crownspire sealed checkpoints.

To begin, I actually do not remember how exactly I figure this out to be a printer service... The only things I can remember are that I was given an instance with an IP and, possibly, a specific port, to which I can neither ping nor do anything meaningful with it. So I input to the LLM the challenge description along with some of my initial guesswork that was previously mentioned, and it told me that I might be dealing with a raw printer socket (Yes, I should have had used `nmap` to inspected the thing, my bad). It was also suggested to me that I'm dealing with PJL (Print Job Language), and connect to it with [PRET](https://github.com/RUB-NDS/PRET).

Connection syntax: 
```
 python3 pret.py 154.57.164.83:32306 pjl
```

Welcome screen: 
```
      ________________                                             
    _/_______________/|                                            
   /___________/___//||   PRET | Printer Exploitation Toolkit v0.40
  |===        |----| ||    by Jens Mueller <jens.a.mueller@rub.de> 
  |           |   ô| ||                                            
  |___________|   ô| ||                                            
  | ||/.´---.||    | ||      「 pentesting tool that made          
  |-||/_____\||-.  | |´         dumpster diving obsolete‥ 」       
  |_||=L==H==||_|__|/                                              
                                                                   
     (ASCII art by                                                 
     Jan Foerster)                                                 
                                                                   
Connection to 154.57.164.83:32306 established
Device:   RiverGate RG-T80II Thermal Receipt Printer

Welcome to the pret shell. Type help or ? to list commands.

```

Then I tried some commands: 
```
154.57.164.83:32306:/> ls
d        -   config
d        -   journal
-       97   readme.txt
d        -   spool
154.57.164.83:32306:/> cat readme.txt
RiverGate RG-T80II raw printer volume.
Electronic journal retention is enabled under 0:/journal.
154.57.164.83:32306:/> id
RiverGate RG-T80II Thermal Receipt Printer
154.57.164.83:32306:/> info config
MODEL=RG-T80II
FIRMWARE=3.18
SERIALNUMBER=RGT80-042-9100
PERSONALITY=PJL,PCL,ESC/POS
EJOURNAL=ON
154.57.164.83:32306:/> printenv
LANG=PJL
RET=ON
EJOURNAL=ON
EJINDEX=NVRAM
```

```
154.57.164.83:32306:/> cd spool
154.57.164.83:32306:/spool> ls
-       79   README.txt
154.57.164.83:32306:/spool> cat README.txt
Active jobs are removed after cut. Closed receipts are retained in 0:/journal.
154.57.164.83:32306:/spool> cd ..
154.57.164.83:32306:/> cd journal/
154.57.164.83:32306:/journal> ls
-       17   last.txt
-      191   receipt_0000.txt
-      192   receipt_0001.txt
-      195   receipt_0002.txt
-      241   receipt_0003.txt
154.57.164.83:32306:/journal> cat last.txt
receipt_0003.txt
EASTREACH RATION KIOSK
------------------------------
DATE: 2026-06-01 00:17:33
GATE: ASH-03
CARGO: BRINE FILTERS
SEAL FEE: 42.10
AUTH CODE: STORED IN NVRAM
NVRAM REF: EJ_AUTH_0421 ADDR=53264 LEN=60
------------------------------
```

I also read other receipt as well, but I only leave the result of receipt_003 here because it is more important than the rest. Notice the: 
```
AUTH CODE: STORED IN NVRAM
NVRAM REF: EJ_AUTH_0421 ADDR=53264 LEN=60
```
Now that's some very interesting lines, isn't it? 

```
NVRAM operations:  nvram <operation>
  nvram dump [all]         - Dump (all) NVRAM to local file.
  nvram read addr          - Read single byte from address.
  nvram write addr value   - Write single byte to address.
```

Read the NVRAM: 
```
154.57.164.83:32306:/journal> nvram read 53264 60
ADDRESS=53264 DATA=72
ASCII="HTB{th3rm4l_j0urn4l_r3c4ll_f346e32e7a4fbc55f3f47291c0e88c75}"
```



## What the shard displayed 
Description: 
The Signet shattered, the great houses fell to arguing with steel, and Alyss, Queen of Quiet Marches, began sending her dead to watch the living. One of her crows fell over our winter line, a maker's device bound beneath its wing — an eye she threaded through dead flesh to count our banners. Fed a current, it still wakes: it checks its roost, marks the hour it last saw us, and paints what it saw onto its pane. Reconstruct it, and learn what her eye found of us before the Hollow Host moves.

It's yet another sigrok file. But it's I2C this time. 

For this one, my own explanation of the challenge won't be suffice and you should read the official write up from HackTheBox themeselves. Because while I was able to obtain the flag, basically how I solve this challenge was throwing things at the data read / data write and playing around with the python script until something works out. It was... very guessy. 

This is my image of the flag:

![[images/flag.png]]

> HTB{3v3ry_crow_w3ar5_h3r_3y3s}
