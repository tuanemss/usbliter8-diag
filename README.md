# usbliter8-diag

This tool helps to boot A12/A13 into Diag mode after use `usbliter8`.

---

## Usage

### Prerequisites
* **Python 3** and **pyusb** for `usbliter8ctl`:
  ```bash
  pip3 install pyusb
  ```
* **libusb** 
  * *macOS:* `brew install libusb`
  * *Linux:* `sudo apt install libusb-1.0-0`

### boot diag
1. put device into DFU mode
2. pwn with usbliter 8
3. ./boot.sh
   ```bash
   chmod +x boot.sh
   ./boot.sh
   ```
---

## Credits

* **[prdgmshift](https://github.com/prdgmshift)**: **usbliter8** and **usbliter8ctl**.
* **[lukezgd](https://github.com/LukeZGD)**: precompiled binary files for Linux, macOS ARM64
* **[Nathan](https://github.com/verygenericname)**: helped me a lot
* **[0cyn](https://github.com/0cyn)** : decrypt keybag t8030
* **[AppInstalleriOSGH](https://github.com/AppInstalleriOSGH)** : decrypt keybag t8020
