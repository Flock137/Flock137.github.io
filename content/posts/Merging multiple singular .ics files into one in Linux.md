---
title: Merging multiple singular .ics files into one in Linux
date: 2025-09-03
draft: false
tags:
  - Misc
  - Tips
---


Step 1: Gather your individual .ics files in a folder. Open the terminal in the said folder. Type this in your console.
```
# Comhbine all .ics to a new text file
cat *.ics > temp.txt 
```

Step 2: If you check with `cat temp.txt` you can see there is this weird string that you need to get rid off: `END:VCALENDARBEGIN:VCALENDAR`. Use `cat temp.txt | grep -v DARBEG > temp1.txt`

Step 3: For my case, I also need to: 
- Adjust so that METHOD, PUBLISH and VERSION only appeared once 
```
# Concatenate temp1.txt; -v means 'inverse grep'
cat temp1.txt | grep -v METHOD -v PRODID -v VERSION > temp2.txt 
```
Note: You need to manually put back your METHOD, PUBLISH and VERSION back manually after using the command above. They should be located after `BEGIN: VCALENDAR` and right before `BEGIN:VEVENT`

- Fix the UID, since they can not be the same. Its syntax should be something like this (rid of the quotes): "mech-a314@synthesis.com", "MECH", "1337", etc. If you see something like '^M' in your text editor, ignore them

Step 4: And finally, 
```
# Export text to iCalendar file. 
cat temp2.txt > calendar.ics
```

Congrats, now all your calendar files are in a file files now. 
Please don't delete your individual .ics files, yet. You might need them later on, they don't take much space.
