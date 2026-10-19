#!/usr/bin/env bash

if ! command -v nmcli >/dev/null || ! command -v ping >/dev/null; then
    echo "This script requires nmcli (NetworkManager) and ping."
    exit 1
fi

while true; do
    echo
    echo "===== Wi-Fi Ping Tool ====="
    echo "1. Monitor Google and restart Wi-Fi if ping fails"
    echo "2. Ping Google a chosen number of times"
    echo "3. Exit"
    read -r -p "Choose an option: " choice

    case "$choice" in
        1)
            echo "Monitoring Google with 3 pings every 30 seconds."
            echo "Press Ctrl+C to stop."
            while true; do
                ping -c 3 -W 2 google.com
                if [ $? -ne 0 ]; then
                    echo "All pings failed. Restarting Wi-Fi..."
                    nmcli radio wifi off
                    sleep 5
                    nmcli radio wifi on
                    sleep 15
                else
                    echo "Ping succeeded."
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
