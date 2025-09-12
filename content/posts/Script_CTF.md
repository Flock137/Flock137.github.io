---
title: ScriptCTF Writeup - Forensics
date: 2025-09-12
draft: true
tags:
  - Writeup
  - Forensics
  - ScriptCTF
---

# pdf
Description: so sad cause no flag in pdf

The challenge attachment can be found here: https://github.com/scriptCTF/scriptCTF2025-OfficialWriteups/blob/main/Forensics/pdf/attachments/challenge.pdf

For this challenge, you can open up Firefox to view the hint in the given PDF, but for this approach, we won't need to use it. All we have to do is using `binwalk`
```
binwalk -e challenge.pdf 
```
In the extracted folder, click on (or `cat`) the text file, the flag is in there
