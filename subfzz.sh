#!/bin/bash

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

function cleanup {
    echo -e "\n${RED}[!] Exiting...${RESET}"
    exit 0
}

trap cleanup SIGINT

if [ "$#" -lt 3 ]; then
    echo -e "${RED}Usage: $0 <domain> <option> [<subdomains_file> or <fuzzing_file>]${RESET}"
    echo -e "${YELLOW}Options:${RESET} ${BLUE}subdomain${RESET} or ${BLUE}fuzz${RESET}"
    exit 1
fi

DOMAIN="$1"
OPTION="$2"

echo -e "${BLUE}[*] Starting process for: $DOMAIN${RESET}"
echo ""

SUBDOMAIN_OUTPUT=""

function check_subdomain {
    FULL_DOMAIN="$1.$DOMAIN"
    if dig +short "$FULL_DOMAIN" | grep -q '^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$'; then
        {
            echo -e "${GREEN}[+] Subdomain found: $FULL_DOMAIN${RESET}"
        } >> subdomain_results.txt
    fi
}

function enumerate_subdomains {
    SUBDOMAINS_FILE="$3"
    if [ ! -f "$SUBDOMAINS_FILE" ]; then
        echo -e "${RED}Subdomains file not found!${RESET}"
        exit 1
    fi
    TOTAL_SUBDOMAINS=$(wc -l < "$SUBDOMAINS_FILE")
    
    echo -e "${YELLOW}[+] Enumerating subdomains...${RESET}"
    COUNT=0
    while IFS= read -r SUBDOMAIN; do
        check_subdomain "$SUBDOMAIN" &

        COUNT=$((COUNT + 1))
        if (( COUNT % 10 == 0 )); then
            PERCENTAGE=$(( COUNT * 100 / TOTAL_SUBDOMAINS ))
            echo -ne "\r${YELLOW}[+] Progress: $PERCENTAGE% (${COUNT}/${TOTAL_SUBDOMAINS})${RESET}"
        fi
    done < "$SUBDOMAINS_FILE"
    wait
    echo -e "\n${YELLOW}[*] Subdomain enumeration completed.${RESET}"
}

function display_subdomain_output {
    if [ -f subdomain_results.txt ]; then
        cat subdomain_results.txt
        rm subdomain_results.txt
    else
        echo -e "${YELLOW}[-] No subdomains found.${RESET}"
    fi
}

function fuzzing {
    FUZZ_FILE="$3"
    if [ ! -f "$FUZZ_FILE" ]; then
        echo -e "${RED}Fuzzing file not found!${RESET}"
        exit 1
    fi
    TOTAL_FUZZ=$(wc -l < "$FUZZ_FILE")
    
    echo -e "${YELLOW}[+] Starting fuzzing on $DOMAIN...${RESET}"
    COUNT=0
    while IFS= read -r FUZZ; do
        URL="http://$DOMAIN/$FUZZ"
        {
            RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
            if [ "$RESPONSE" -ne 404 ]; then
                echo -e "${GREEN}[+] Fuzzing found: $URL (Response code: $RESPONSE)${RESET}"
            fi
        } > /dev/null 2>&1 &

        COUNT=$((COUNT + 1))
        if (( COUNT % 10 == 0 )); then
            PERCENTAGE=$(( COUNT * 100 / TOTAL_FUZZ ))
            echo -ne "\r${YELLOW}[+] Fuzzing Progress: $PERCENTAGE% (${COUNT}/${TOTAL_FUZZ})${RESET}"
        fi
    done < "$FUZZ_FILE"
    wait
    echo -e "\n${YELLOW}[*] Fuzzing completed.${RESET}"
}

if [ "$OPTION" == "subdomain" ]; then
    if [ "$#" -ne 3 ]; then
        echo -e "${RED}Please provide a subdomains file for subdomain enumeration.${RESET}"
        exit 1
    fi
    enumerate_subdomains "$DOMAIN" "$OPTION" "$3"
    display_subdomain_output
elif [ "$OPTION" == "fuzz" ]; then
    if [ "$#" -ne 3 ]; then
        echo -e "${RED}Please provide a fuzzing file for fuzzing.${RESET}"
        exit 1
    fi
    fuzzing "$DOMAIN" "$OPTION" "$3"
else
    echo -e "${RED}Invalid option! Use 'subdomain' or 'fuzz'.${RESET}"
    exit 1
fi

