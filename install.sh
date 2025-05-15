#!/bin/bash

# WARP Scanner v1.3.80 - Optimized & Fixed

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

VERSION="1.3.80"
PING_COUNT=5
TIMEOUT=2
MIN_SUCCESS_RATE=80

PREFIX=${PREFIX:-/usr/local}

# Loading animation
show_loading() {
    local pid=$1
    local delay=0.2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " %c  Scanning endpoints..." "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        echo -en "\r"
        sleep $delay
    done
    echo -en "\r"
}

# Generate WireGuard URL
generate_wireguard_url() {
    local ip=$1
    local private_key=$(wg genkey)
    local base_ip=$(echo "$ip" | cut -d':' -f1)
    local port=$(echo "$ip" | cut -d':' -f2)
    echo "wireguard://${private_key}@${base_ip}:${port}?address=172.16.0.2/32&presharedkey=&reserved=125,208,143&publickey=bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=&mtu=1280#@void1x0"
}

print_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${PURPLE}             WARP SCANNER              ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}       Optimized version with WHA         ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}               Version ${VERSION}              ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo -e "${PURPLE}              By: void1x0${NC}\n"
}

check_cpu() {
    case "$(uname -m)" in
        x86_64|amd64) cpu=amd64 ;;
        i386|i686) cpu=386 ;;
        armv8*|arm64|aarch64) cpu=arm64 ;;
        armv7l) cpu=arm ;;
        *)
            echo -e "${RED}Unsupported architecture: $(uname -m)${NC}"
            exit 1 ;;
    esac
}

setup_warpendpoint() {
    if [[ ! -f "$PREFIX/bin/warpendpoint" ]]; then
        echo -e "${CYAN}Downloading warpendpoint...${NC}"
        curl -L -o warpendpoint -# --retry 2 "https://raw.githubusercontent.com/void1x0/warp/main/endip/$cpu" || {
            echo -e "${RED}Failed to download warpendpoint${NC}"
            exit 1
        }
        cp warpendpoint "$PREFIX/bin"
        chmod +x "$PREFIX/bin/warpendpoint"
    fi
}

generate_ipv4() {
    n=0
    iplist=100
    while [ $n -lt $iplist ]; do
        temp[$n]=$(echo "162.159.192.$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "162.159.193.$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "162.159.195.$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "188.114.96.$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "188.114.97.$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "188.114.98.$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "188.114.99.$(($RANDOM % 256))"); n=$((n + 1))

        temp[$n]=$(echo "173.245.$((48 + RANDOM % 16)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "103.21.$((244 + RANDOM % 4)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "103.22.$((200 + RANDOM % 4)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "103.31.$((4 + RANDOM % 4)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "141.101.$((64 + RANDOM % 64)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "108.162.$((192 + RANDOM % 64)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "190.93.$((240 + RANDOM % 16)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "188.114.$((96 + RANDOM % 16)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "197.234.$((240 + RANDOM % 4)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "198.41.$((128 + RANDOM % 128)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "162.$((158 + RANDOM % 2)).$(($RANDOM % 256)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "104.$((16 + RANDOM % 32)).$(($RANDOM % 256)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "104.$((24 + RANDOM % 16)).$(($RANDOM % 256)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "172.$((64 + RANDOM % 8)).$(($RANDOM % 256)).$(($RANDOM % 256))"); n=$((n + 1))
        temp[$n]=$(echo "131.0.$((72 + RANDOM % 4)).$(($RANDOM % 256))"); n=$((n + 1))
    done

    printf "%s\n" "${temp[@]}" > ip.txt
}

process_results() {
    warpendpoint &
    show_loading $!
    wait

    if [ ! -f "result.csv" ]; then
        echo -e "${RED}Error: Failed to generate results.${NC}"
        exit 1
    fi

    clear
    echo -e "${BLUE}╔═════════════ SCAN RESULTS ═════════════╗${NC}"
    cat result.csv | awk -F, '$3!="timeout ms" {print} ' | sort -t, -nk2 -nk3 | uniq | head -11 | \
    awk -F, '{
        success_rate = 100 - $2
        quality = "Poor"
        if (success_rate >= 95 && $3 <= 100) quality = "Excellent"
        else if (success_rate >= 90 && $3 <= 150) quality = "Good"
        else if (success_rate >= 85 && $3 <= 200) quality = "Fair"
        printf "║ %-25s │ %5.1f%% │ %-6s │ %-9s ║\n", $1, success_rate, $3, quality
    }'
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}\n"

    best_ip=$(awk -F, 'NR==2 {print $1}' result.csv)
    delay=$(grep -oE "[0-9]+ ms|timeout" result.csv | head -n 1)
    success_rate=$(awk -F, 'NR==2 {print 100-$2}' result.csv)

    echo -e "${PURPLE}Best Endpoint Found:${NC}"
    echo -e "${WHITE}$best_ip${NC}"
    echo -e "${YELLOW}Delay: $delay │ Success Rate: ${success_rate}%${NC}\n"

    echo -e "${PURPLE}Warp Hiddify App (WHA) URL:${NC}"
    echo -e "${WHITE}warp://${best_ip}/?ifp=5-10@void1x0${NC}\n"

    echo -e "${PURPLE}WireGuard URL for v2ray:${NC}"
    echo -e "${WHITE}$(generate_wireguard_url "$best_ip")${NC}\n"

    rm -f warpendpoint ip.txt 2>/dev/null
}

show_menu() {
    echo -e "${BLUE}╔═════════════ SELECT MODE ════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${GREEN}1${NC}. Scan for IPv4 Endpoints          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC} ${RED}0${NC}. Exit                             ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo -en "${CYAN}Enter your choice: ${NC}"
}

main() {
    print_header
    check_cpu
    setup_warpendpoint

    while true; do
        show_menu
        read -r choice
        case "$choice" in
            1)
                echo -e "\n${CYAN}Starting IPv4 endpoint scan...${NC}"
                generate_ipv4
                process_results
                ;;
            0)
                echo -e "\n${GREEN}Thank you for using WARP Scanner!${NC}"
                exit 0 ;;
            *)
                echo -e "\n${RED}Invalid choice. Please try again.${NC}" ;;
        esac
    done
}

main
