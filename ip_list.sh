#!/bin/bash

read -p "Enter the base IP address (e.g., 10.5.86): " BASE_IP
read -p "Enter the starting host number (e.g., 1): " START
read -p "Enter the ending host number (e.g., 254): " END

PORTS=(445 3389 22 135 9100 631 80 443)

echo ""
echo "----------------------------------------"
echo "Scanning IP range: ${BASE_IP}.${START} to ${BASE_IP}.${END}"
echo "----------------------------------------"

is_ip_assigned() {
    local ip="$1"

    # 1. Send a quick packet to populate/refresh ARP, then check ARP neighbor table
    ping -c 1 -W 1 "$ip" &> /dev/null
    if ip neigh show "$ip" 2>/dev/null | grep -qE "REACHABLE|STALE|DELAY|PROBE"; then
        return 0
    fi

    # 2. Check common TCP ports if nc is available
    if command -v nc &> /dev/null; then
        for port in "${PORTS[@]}"; do
            if nc -z -w 1 "$ip" "$port" &> /dev/null; then
                return 0
            fi
        done
    fi

    return 1
}

for ((i=START; i<=END; i++)); do
    IP="${BASE_IP}.$i"
    if is_ip_assigned "$IP"; then
        echo "$IP - Assigned"
    else
        echo "$IP - Free"
    fi
done

echo "----------------------------------------"
echo "Scan complete."
