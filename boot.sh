#!/bin/bash

OS_TYPE=$(uname -s)
ARCH_TYPE=$(uname -m)

if [ "$OS_TYPE" = "Darwin" ]; then
    if [ "$ARCH_TYPE" = "arm64" ] && [ -f "$(dirname "$0")/bin/macos/arm64/irecovery" ]; then
        IRECOVERY="$(dirname "$0")/bin/macos/arm64/irecovery"
    elif [ -f "$(dirname "$0")/bin/macos/irecovery" ]; then
        IRECOVERY="$(dirname "$0")/bin/macos/irecovery"
    else
        IRECOVERY="irecovery"
    fi
elif [ "$OS_TYPE" = "Linux" ]; then
    if [ -f "$(dirname "$0")/bin/linux/irecovery" ]; then
        IRECOVERY="$(dirname "$0")/bin/linux/irecovery"
    else
        IRECOVERY="irecovery"
    fi
else
    IRECOVERY="irecovery"
fi

if [ "$IRECOVERY" != "irecovery" ] && [ ! -f "$IRECOVERY" ]; then
    IRECOVERY="irecovery"
fi

echo "[*] Checking for connected DFU device..."
irecovery_info=$("$IRECOVERY" -q 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$irecovery_info" ]; then
    echo "[-] Error: No device found in DFU mode. Please connect your device in DFU mode."
    exit 1
fi

#check PWWNED: usbliter8
if ! echo "$irecovery_info" | grep -iq "PWND"; then
    echo "[-] Error: Device is NOT in PWNED DFU mode! Please run usbliter8 first."
    exit 1
fi


PRODUCT=$(echo "$irecovery_info" | grep -oE "PRODUCT:[^ ]+" | cut -d: -f2 | tr -d ' ' | tr '[:lower:]' '[:upper:]')
if [ -z "$PRODUCT" ]; then
    PRODUCT=$(echo "$irecovery_info" | grep -i "PRODUCT:" | awk '{print $2}' | tr '[:lower:]' '[:upper:]')
fi

MODEL=$(echo "$irecovery_info" | grep -oE "MODEL:[^ ]+" | cut -d: -f2 | tr -d ' ' | tr '[:lower:]' '[:upper:]')
if [ -z "$MODEL" ]; then
    MODEL=$(echo "$irecovery_info" | grep -i "MODEL:" | awk '{print $2}' | tr '[:lower:]' '[:upper:]')
fi

PRODUCT=$(echo "$PRODUCT" | tr -d '\r\n')
MODEL=$(echo "$MODEL" | tr -d '\r\n')

SOC_DIR=""
DEVICE_DIR=""


case "$PRODUCT" in
    # A12 Bionic (t8020): iPhone XR, XS, XS Max, iPad Mini 5, iPad Air 3, iPad 8
    *IPHONE11,8*|*IPHONE11,2*|*IPHONE11,4*|*IPHONE11,6*|*IPAD11,1*|*IPAD11,2*|*IPAD11,3*|*IPAD11,4*|*IPAD11,6*|*IPAD11,7*)
        SOC_DIR="t8020"
        ;;
    # A13 Bionic (t8030): iPhone 11, 11 Pro, 11 Pro Max, SE 2020, iPad 9
    *IPHONE12,1*|*IPHONE12,3*|*IPHONE12,5*|*IPHONE12,8*|*IPAD12,1*|*IPAD12,2*)
        SOC_DIR="t8030"
        ;;
esac

if [ -z "$SOC_DIR" ]; then
    case "$MODEL" in
        # A12 Board IDs: N84AP (XR), D321AP (XS), D331PAP/D331AP (XS Max), J210AP/J211AP (Mini 5), J217AP/J218AP (Air 3), J171AP/J172AP (iPad 8)
        *N84AP*|*D321AP*|*D331PAP*|*D331AP*|*J210AP*|*J211AP*|*J217AP*|*J218AP*|*J171AP*|*J172AP*)
            SOC_DIR="t8020"
            ;;
        # A13 Board IDs: N104AP (11), D421AP (11 Pro), D431AP (11 Pro Max), D79AP (SE 2020), J181AP/J182AP (iPad 9)
        *N104AP*|*D421AP*|*D431AP*|*D79AP*|*J181AP*|*J182AP*)
            SOC_DIR="t8030"
            ;;
    esac
fi


DEVICE_DIR="$MODEL"


if [ -z "$DEVICE_DIR" ] && [ -n "$PRODUCT" ]; then
    case "$PRODUCT" in
        *IPHONE11,8*)            DEVICE_DIR="N84AP" ;;   # iPhone XR
        *IPHONE11,2*)            DEVICE_DIR="D321AP" ;;  # iPhone XS
        *IPHONE11,4*|*IPHONE11,6*) DEVICE_DIR="D331PAP" ;; # iPhone XS Max
        *IPHONE12,1*)            DEVICE_DIR="N104AP" ;;  # iPhone 11
        *IPHONE12,3*)            DEVICE_DIR="D421AP" ;;  # iPhone 11 Pro
        *IPHONE12,5*)            DEVICE_DIR="D431AP" ;;  # iPhone 11 Pro Max
        *IPHONE12,8*)            DEVICE_DIR="D79AP" ;;   # iPhone SE 2
        *IPAD11,1*)              DEVICE_DIR="J210AP" ;;  # iPad Mini 5 Wifi
        *IPAD11,2*)              DEVICE_DIR="J211AP" ;;  # iPad Mini 5 Cellular
        *IPAD11,3*)              DEVICE_DIR="J217AP" ;;  # iPad Air 3 Wifi
        *IPAD11,4*)              DEVICE_DIR="J218AP" ;;  # iPad Air 3 Cellular
        *IPAD11,6*)              DEVICE_DIR="J171AP" ;;  # iPad 8 Wifi
        *IPAD11,7*)              DEVICE_DIR="J172AP" ;;  # iPad 8 Cellular
        *IPAD12,1*)              DEVICE_DIR="J181AP" ;;  # iPad 9 Wifi
        *IPAD12,2*)              DEVICE_DIR="J182AP" ;;  # iPad 9 Cellular
    esac
fi

if [ -z "$DEVICE_DIR" ] || [ -z "$SOC_DIR" ]; then
    echo "[-] Error: Unsupported device (PRODUCT: $PRODUCT, MODEL: $MODEL)."
    exit 1
fi

echo "[+] Detected device: $SOC_DIR/$DEVICE_DIR (PRODUCT: $PRODUCT, MODEL: $MODEL)"

BOOTCHAIN_DIR="resources/bootchain/$SOC_DIR/$DEVICE_DIR"
if [ ! -d "$BOOTCHAIN_DIR" ]; then
    echo "[-] Error: Bootchain directory does not exist: $BOOTCHAIN_DIR"
    exit 1
fi

IBSS_PATH="$BOOTCHAIN_DIR/ibss.raw"
DIAG_PATH="$BOOTCHAIN_DIR/diag.img4"

if [ ! -f "$IBSS_PATH" ]; then
    echo "[-] Error: Could not find ibss.raw file in $BOOTCHAIN_DIR"
    exit 1
fi

if [ ! -f "$DIAG_PATH" ]; then
    echo "[-] Error: Could not find diag file in $BOOTCHAIN_DIR"
    exit 1
fi


echo ""
echo "[*] Booting raw iBSS using usbliter8ctl..."
python3 resources/usbliter8ctl boot "$IBSS_PATH"
if [ $? -ne 0 ]; then
    echo "[-] Error: usbliter8ctl boot failed."
    exit 1
fi
echo "[+] iBSS booted successfully."

sleep 3

echo ""
echo "[*] Waiting for device to connect in recovery/iBoot mode..."
CONNECTED=false
for i in {1..30}; do
    if "$IRECOVERY" -q >/dev/null 2>&1; then
        CONNECTED=true
        break
    fi
    sleep 0.5
done

if [ "$CONNECTED" = false ]; then
    echo "[-] Error: Device did not connect in recovery mode within 15 seconds."
    exit 1
fi
echo "[+] Device connected in recovery mode."


"$IRECOVERY" -q | grep -E "PRODUCT:|MODEL:|MODE:" 2>/dev/null

sleep 2
#boot-agrs , maybe....
echo ""
echo "[*] setenv boot-args usbserial=enable"
"$IRECOVERY" -c "setenvnp boot-args usbserial=enable"
sleep 1
"$IRECOVERY" -c "saveenv"

if [ $? -ne 0 ]; then
    echo "[-] Error: Failed to set boot-args."
    exit 1
fi

#Send diag file
echo "[*] Sending diag file..."
"$IRECOVERY" -f "$DIAG_PATH"
if [ $? -ne 0 ]; then
    echo "[-] Error: Failed to upload diag file."
    exit 1
fi

echo "[*] Booting diag"
"$IRECOVERY" -c "go" 2>/dev/null

echo ""
echo "[+] completed! The device should now boot into Diag mode."
