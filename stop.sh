#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${GREEN}[+]${NC} Stopping Bot Group Chat servers..."

stopped=0
for port in 3000 3001; do
    pid=$(lsof -ti tcp:$port 2>/dev/null)
    if [ -n "$pid" ]; then
        kill $pid 2>/dev/null
        stopped=1
    fi
done

if [ $stopped -eq 1 ]; then
    echo -e "${GREEN}[+]${NC} Servers stopped."
else
    echo -e "${YELLOW}[!]${NC} No servers running on ports 3000 or 3001."
fi
echo ""
