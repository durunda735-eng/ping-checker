#!/usr/bin/env bash

# =====================================================================
# DEPENDENCIES
# This section ensures the necessary tools are installed on system
# It silently checks for 'nmcli' (NetworkManager) and 'ping'.
# If either is missing, it alerts and stops the script.
# =====================================================================
if ! command -v nmcli >/dev/null || ! command -v ping >/dev/null; then
    echo "ERROR: This script requires 'nmcli' (NetworkManager) and 'ping'."
    exit 1
fi

# =====================================================================
# ADMIN RIGHTS CHECK
# Disabling and enabling network hardware on Linux usually requires 
# root access. This checks if the Effective User ID (EUID) is 0 (root).
# =====================================================================
if [ "$EUID" -ne 0 ]; then
    echo "==================================================="
    echo "ERROR: Administrator Privileges Required!"
    echo "==================================================="
    echo "Please run this script with sudo (e.g., sudo ./linux_monitor.sh)"
    exit 1
fi

# =====================================================================
# ADAPTER DETECTION
# This asks the Linux IP routing table for the default route to the 
# internet, extracts the actual hardware device name (like eth0 or wlp3s0),
# and saves it as ACTIVE_ADAPTER so there is no need to guess the name.
# =====================================================================
echo "Detecting your active network adapter..."
ACTIVE_ADAPTER=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

if [ -z "$ACTIVE_ADAPTER" ]; then
    echo "ERROR: Could not detect an active internet connection."
    echo "Please connect to Wi-Fi or Ethernet first."
    exit 1
fi

# =====================================================================
# MAIN MENU LOOP
# Uses a 'while true' loop to keep showing the menu until exit.
# It reads user input into the 'choice' variable and uses a 'case' 
# statement to trigger the right section.
# =====================================================================
while true; do
    echo
    echo "===== Connection Ping Tool ====="
    echo "Monitoring Adapter: $ACTIVE_ADAPTER"
    echo "================================"
    echo "1. Monitor Google and restart adapter if ping fails"
    echo "2. Ping Google a chosen number of times"
    echo "3. Exit"
    read -r -p "Choose an option: " choice

    case "$choice" in
        1)
            # =====================================================================
            # THE MONITORING LOOP
            # Pings Google 3 times. The >/dev/null 2>&1 part hides the raw 
            # ping output from cluttering user screen. If it fails, it uses 
            # nmcli to disconnect and reconnect the specific adapter found.
            # =====================================================================
            echo "Monitoring Google with 3 pings every 30 seconds."
            echo "Target adapter: $ACTIVE_ADAPTER"
            echo "Press Ctrl+C to stop."
            
            while true; do
                if ping -c 3 -W 2 google.com >/dev/null 2>&1; then
                    echo "Ping succeeded."
                else
                    echo "Ping failed. Restarting $ACTIVE_ADAPTER..."
                    nmcli device disconnect "$ACTIVE_ADAPTER" >/dev/null 2>&1
                    sleep 5
                    nmcli device connect "$ACTIVE_ADAPTER" >/dev/null 2>&1
                    sleep 15
                fi
                echo "Checking again in 30 seconds..."
                sleep 30
            done
            ;;
        2)
            # =====================================================================
            # MANUAL PING
            # Asks how many times to ping. The strange looking [[ ... ]] line 
            # is a "Regular Expression" that ensures you actually typed a 
            # positive number and not letters.
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