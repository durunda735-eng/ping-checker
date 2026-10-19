#!/bin/bash

# Change this if your Wi-Fi device isn't en0.
# Find the right device with: networksetup -listallhardwareports
WIFI_IF="en0"

while true; do
    echo
    echo "===== macOS Wi-Fi Ping Tool ====="
    echo "1. Monitor Google and restart Wi-Fi if all pings fail"
    echo "2. Ping Google a chosen number of times"
    echo "3. Exit"
    read -r -p "Choose an option: " choice

    case "$choice" in
        1)
            echo "Monitoring Google with 3 pings every 30 seconds."
            echo "Press Ctrl+C to stop."

            while true; do
                echo
                if ping -c 3 google.com; then
                    echo "At least one ping succeeded."
                else
                    echo "No ping replies. Restarting Wi-Fi ($WIFI_IF)..."
                    networksetup -setairportpower "$WIFI_IF" off
                    sleep 5
                    networksetup -setairportpower "$WIFI_IF" on
                    sleep 15
                fi

                echo "Checking again in 30 seconds..."
                sleep 30
            done
            ;;
        2)
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
