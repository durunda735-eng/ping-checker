#!/bin/bash

# =====================================================================
# ADMIN RIGHTS CHECK
# Changing network states on macOS requires root privileges.
# This section checks if the Effective User ID (EUID) is 0 (root).
# If not, it warns user to run the script with 'sudo'.
# =====================================================================
if [ "$EUID" -ne 0 ]; then
    echo "==================================================="
    echo "ERROR: Administrator Privileges Required!"
    echo "==================================================="
    echo "Please run this script with sudo (e.g., sudo ./mac_monitor.sh)"
    exit 1
fi

# =====================================================================
# ADAPTER DETECTION
# This asks for the default internet route to get the active
# device name (e.g., en0 or en1). 
# It then translates that raw device name into the UI service name 
# (e.g., "Wi-Fi" or "Ethernet") so the restart command targets correctly.
# =====================================================================
echo "Detecting your active network adapter..."
ACTIVE_DEVICE=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')

if [ -z "$ACTIVE_DEVICE" ]; then
    echo "ERROR: Could not detect an active internet connection."
    echo "Please connect to Wi-Fi or Ethernet first."
    exit 1
fi

# Translates the device name (en0) into the readable service name (Wi-Fi)
ACTIVE_SERVICE=$(networksetup -listallhardwareports | awk "/Device: $ACTIVE_DEVICE/ {print prev} {prev=\$0}" | sed 's/Hardware Port: //')

# =====================================================================
# MAIN MENU LOOP
# Uses a 'while true' loop to keep showing the menu until user exit.
# It reads user input into the 'choice' variable and uses a 'case' 
# statement to trigger the right section.
# =====================================================================
while true; do
    echo
    echo "===== Connection Ping Tool ====="
    echo "Monitoring Adapter: $ACTIVE_SERVICE ($ACTIVE_DEVICE)"
    echo "================================"
    echo "1. Monitor Google and restart adapter if ping fails"
    echo "2. Ping Google a chosen number of times"
    echo "3. Exit"
    read -r -p "Choose an option: " choice

    case "$choice" in
        1)
            # =====================================================================
            # THE MONITORING LOOP
            # Pings Google 3 times. The >/dev/null 2>&1 hides the raw ping text. 
            # If it fails, it uses 'networksetup' to disable and enable the 
            # specific service found. This works universally for all adapters.
            # =====================================================================
            echo "Monitoring Google with 3 pings every 30 seconds."
            echo "Target adapter: $ACTIVE_SERVICE"
            echo "Press Ctrl+C to stop."
            
            while true; do
                if ping -c 3 google.com >/dev/null 2>&1; then
                    echo "Ping succeeded."
                else
                    echo "Ping failed. Restarting $ACTIVE_SERVICE..."
                    networksetup -setnetworkserviceenabled "$ACTIVE_SERVICE" off
                    sleep 5
                    networksetup -setnetworkserviceenabled "$ACTIVE_SERVICE" on
                    sleep 15
                fi
                echo "Checking again in 30 seconds..."
                sleep 30
            done
            ;;
        2)
            # =====================================================================
            # MANUAL PING
            # Asks how many times to ping. The [[ ... ]] line is a Regular 
            # Expression that ensures you actually typed a positive whole number.
            # =====================================================================
            read -r -p "How many times should it ping Google? " count
            if [[ "$count" =~ ^[1-9][0-9]*$ ]]; then
                ping -c "$count" google.com
            else
                echo "Enter a positive whole number."
            fi
            ;;
        3)
            exit 0
            ;;
        *)
            echo "Choose 1, 2, or 3."
            ;;
    esac
done