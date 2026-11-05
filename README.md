# USB-Explorer / GPLControl Worm: Cleaner and Vaccine

Free tools to **remove** the `USB-Explorer.exe` / `GPLControl.exe` USB worm, **restore your hidden files**, and **vaccinate** USB drives so this worm can't infect them again.

> **Symptoms:** your USB drive suddenly looks empty but is still full, there's a `USB-Explorer.exe` on it, and your files are hidden inside `Explorer\MAYUNDO`.
> **Your files aren't deleted.** The worm only moves and hides them.

---

## Quick start

### 1. Clean every Windows PC the drive has been plugged into
Download [`windows/clean-pc.bat`](windows/clean-pc.bat) and double-click it. Do this while signed in as **each** user who plugged in the drive. Then run a **Full scan** in Windows Security.

### 2. Clean and vaccinate the USB drive

**Windows:** put `clean-usb.bat` and `vaccinate-usb.bat` in the same folder, open Command Prompt there, and run (change `E:` to your USB drive):
```bat
clean-usb.bat E:
```

**Linux** (safest, because the worm can't run on Linux):
```bash
./linux/clean-and-vaccinate.sh /media/$USER/YOUR_DRIVE            # quarantines the worm file
./linux/clean-and-vaccinate.sh /media/$USER/YOUR_DRIVE --delete   # deletes it instead
```

### 3. Vaccinate clean drives too
```bat
vaccinate-usb.bat F:
```
Run it on every USB stick and on **every partition** of an external disk.

> ⚠️ **Never double-click `USB-Explorer.exe`** or any `.exe` on a USB drive that looks like a folder. Turn on **View > Show > File name extensions** and **Hidden items** in File Explorer.

---

## What's in this repository

| File | What it does |
|---|---|
| `windows/clean-pc.bat` | Stops `GPLControl.exe`, removes its startup entry, deletes `C:\Users\Public\Libraries\GPLControl.exe`, and checks the result |
| `windows/clean-usb.bat` | Deletes `USB-Explorer.exe` from the drive, moves your files back from `Explorer\MAYUNDO` (never overwrites anything), removes the hiding folder, then vaccinates |
| `windows/vaccinate-usb.bat` | Creates the two protection items on a clean drive. Refuses to touch C: and refuses infected drives |
| `linux/clean-and-vaccinate.sh` | Does the same clean, restore and vaccinate steps from Linux |
| `tests/simulate_worm_logic.py` | Harmless re-implementation of the worm's drive logic (not the worm), used to show the vaccine works |

The scripts are tested on Linux and under Wine. **No worm sample is included in this repository.**

---

## How the vaccine works

The worm only checks **whether something with a given name already exists**, not whether it's a file or a folder. The vaccine takes its two names first:

| Created at the drive root | Type | Effect |
|---|---|---|
| `Explorer` | read-only **file** | The worm doesn't create its hiding folder. Every attempt to move your files into `Explorer\MAYUNDO` fails, because `Explorer` is a file. **Your files stay where they are.** |
| `USB-Explorer.exe` | read-only **folder** | The worm can't create its lure file with the same name. **No worm is dropped.** |

**Don't delete these two items.** Each one has a note explaining what it is.

### Test result
```
$ python3 tests/simulate_worm_logic.py
unprotected: files left in place=False, worm dropped=True
vaccinated:  files left in place=True, worm dropped=False
PASS: the vaccine blocks the worm logic
```

### Limits
- The vaccine blocks **this worm as it works now**. A future version that uses different names would get past it.
- `autorun.inf` "vaccines" (360, Panda USB Vaccine and others) **don't** stop this worm, because it deliberately ignores `autorun.inf`. Keep them anyway; they help against older worms.
- **The real cure is a clean PC.** The vaccine is a second line of defence.

---

## Indicators of compromise

### Files
| Location | Name |
|---|---|
| USB drive root | `USB-Explorer.exe` (the lure program) |
| USB drive root | `Explorer\` (hidden), containing `MAYUNDO\` (your moved files) |
| Infected PC | `C:\Users\Public\Libraries\GPLControl.exe` |

### Registry
```
HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
    GPLControl  REG_SZ  C:\Users\Public\Libraries\GPLControl.exe
```

### Process
`GPLControl.exe`

### Samples seen (SHA-256)
| Version | Size (bytes) | SHA-256 |
|---|---|---|
| v1 | 5,242,880 | `fdcdec7a76be5f422bd8830e2ab0f821dfab9e4da42c323b8b71dc76ec51cddd` |
| v2 | 7,546,516 | `3f3e84744c41d44ce8ec2cbbb6e97b837b5ea9e18cadee57781497ad23d80e09` |

### Static traits
- 64-bit Windows GUI program, unsigned, with no version information.
- Built with PyInstaller on Python 3.11 (`_MEIPASS`, `python311.dll`).
- Main script name: `Console-USBExplora 02-03-2024.py`.
- Uses the Python libraries `psutil`, `shutil`, `threading` and `os`.

---

## Technical analysis

The analysis was static. The PyInstaller archive was unpacked and the Python 3.11 bytecode was disassembled; the worm was never run.

### Mode A: run as `USB-Explorer.exe` (the victim clicks it)
1. If `C:\Users\Public\Libraries\GPLControl.exe` is missing, the worm copies itself there and runs:
   ```
   REG ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v GPLControl /t REG_SZ /d C:\Users\Public\Libraries\GPLControl.exe /f
   ```
2. It opens `Explorer\MAYUNDO` (`os.startfile`) so the victim sees their files.
3. It exits. The background copy starts at the next login.

### Mode B: run as `GPLControl.exe` (at every login), looping every 5 seconds
```python
# Reconstruction from the bytecode (simplified)
WHITELIST = ['Explorer', 'USB-Explorer.exe', 'autorun.inf', 'System Volume Information']

def getDisk():      # drive letters A, B, D..Z that exist (C: skipped on purpose)
    return [L + ':\\' for L in 'ABDEFGHIJKLMNOPQRSTUVWXYZ' if exists(L + ':\\')]

def InternalDisk(): # partitions reported as 'rw,fixed' are skipped
    return [p.device for p in psutil.disk_partitions() if p.opts == 'rw,fixed']

def infectDisk():
    if not exists(r'C:\Users\Public\Libraries\GPLControl.exe'):   # re-installs itself if removed
        copy(self, r'C:\Users\Public\Libraries\GPLControl.exe'); register()
    for disk in getDisk():
        if disk not in InternalDisk() and disk not in already_done:
            already_done.append(disk)
            if not exists(disk + 'Explorer'):
                makedirs(disk + r'Explorer\MAYUNDO')
                popen('ATTRIB ' + disk + 'Explorer +H')
            if not exists(disk + 'USB-Explorer.exe'):
                copy(self, disk + 'USB-Explorer.exe')
            if exists(disk + 'Explorer'):
                for item in listdir(disk):
                    if item not in WHITELIST:
                        try: move(disk + '\\' + item, disk + r'Explorer\MAYUNDO')
                        except: ...
    for disk in already_done:                  # drives still plugged in
        if not exists(disk + 'USB-Explorer.exe'):
            copy(self, disk + 'USB-Explorer.exe')   # the lure comes back within 5 s if deleted
```

### What this means
- If you delete `USB-Explorer.exe` while the drive is plugged into an infected PC, **it comes back within 5 seconds**. Clean the PC first.
- Every partition or drive letter gets its own copy.
- No network, encryption or file-deletion code was found in the main script.

---

## Manual removal (without the scripts)

### On the infected PC
1. **Task Manager**: end `GPLControl.exe`, then disable **GPLControl** under *Startup apps*.
2. Delete `C:\Users\Public\Libraries\GPLControl.exe`.
3. Run `regedit`, go to `HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run`, and delete `GPLControl`.
4. Run a Full scan with Microsoft Defender or Malwarebytes.

### On the USB drive (from a clean PC)
1. Turn on **Hidden items** and **File name extensions**.
2. Right-click `USB-Explorer.exe` and choose **Delete**. Don't open it.
3. Open `Explorer\MAYUNDO`, select all, **Cut**, then **Paste** at the drive root.
4. Delete the empty `Explorer` folder.
5. Vaccinate the drive (see above).

---

## Prevention
- Don't run cracked software, keygens or "activators". They're the usual way this kind of worm gets in.
- Be careful with shared PCs (cyber cafés, labs, printing shops).
- Keep Microsoft Defender on, and scan USB drives before opening them.
- When in doubt, open unknown USB drives on Linux, where Windows worms can't run.

## License
MIT. See [LICENSE](LICENSE). Provided as is, without warranty. Back up important data before running any cleanup tool.
