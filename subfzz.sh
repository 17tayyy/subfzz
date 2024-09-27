#!/bin/bash

ASCII_ART='
\033[1;36m ______   __  __    _______   ______   ______    ______     
/_____/\ /_/\/_/\ /_______/\ /_____/\ /_____/\  /_____/\    
\::::_\/_\:\ \:\ \\::: _  \ \\::::_\/_\:::__\/  \:::__\/    
 \:\/___/\\:\ \:\ \\::(_)  \/_\:\/___/\  /: /      /: /     
  \_::._\:\\:\ \:\ \\::  _  \ \\:::._\/ /::/___   /::/___   
    /____\:\\:\_\:\ \\::(_)  \ \\:\ \  /_:/____/\/_:/____/\ 
    \_____\/ \_____\/ \_______\/ \_\/  \_______\/\_______\/ 
     
     
     by: tay \033[0m
'

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

echo -e "\n"
echo -e "$ASCII_ART"
echo -e "\n"

function cleanup {
    echo -e "\n${RED}[!] Exiting...${RESET}"
    exit 0
}

trap cleanup SIGINT

if [ "$#" -lt 3 ]; then
    echo -e "${RED}[!] Usage: $0 <domain> <option> [<subdomains_file> or <fuzzing_file>]${RESET}"
    echo -e "${YELLOW}[Options: subdomain or fuzz]${RESET}"
    exit 1
fi

DOMAIN="$1"
OPTION="$2"

if [ -f subdomain_results.txt ]; then
    rm subdomain_results.txt
    echo -e "${GREEN}[+] Old subdomain results file deleted.${RESET}"
fi

if [ -f fuzz_results.txt ]; then
    rm fuzz_results.txt
    echo -e "${GREEN}[+] Old fuzz results file deleted.${RESET}"
fi

echo -e "${BLUE}[*] Starting process for: $DOMAIN${RESET}"

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
        echo -e "${RED}[!] Subdomains file not found!${RESET}"
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
        echo -e "${GREEN}[+] Results saved in subdomain_results.txt${RESET}"
        cat subdomain_results.txt
    else
        echo -e "${YELLOW}[-] No subdomains found.${RESET}"
    fi
}

function fuzzing {
    FUZZ_FILE="$3"
    if [ ! -f "$FUZZ_FILE" ]; then
        echo -e "${RED}[!] Fuzzing file not found!${RESET}"
        exit 1
    fi

    TOTAL_FUZZ=$(wc -l < "$FUZZ_FILE")
    COUNT=0
    echo -e "${YELLOW}[+] Starting fuzzing on $DOMAIN...${RESET}"

    function perform_fuzz {
        local FUZZ="$1"
        URL="http://$DOMAIN/$FUZZ"
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
        if [ "$RESPONSE" -ne 404 ] && [ "$RESPONSE" -ne 403 ]; then
            {
                echo -e "${GREEN}[+] Fuzzing found: $URL (Response code: $RESPONSE)${RESET}"
                echo "$URL (Response code: $RESPONSE)" >> fuzz_results.txt
            }
        fi
    }

    while IFS= read -r FUZZ; do
        if [[ -z "$FUZZ" || "$FUZZ" == \#* ]]; then
            continue
        fi
        perform_fuzz "$FUZZ" &

        COUNT=$((COUNT + 1))
        if (( COUNT % 10 == 0 )); then
            PERCENTAGE=$(( COUNT * 100 / TOTAL_FUZZ ))
            echo -ne "\r${YELLOW}[+] Fuzzing Progress: $PERCENTAGE% (${COUNT}/${TOTAL_FUZZ})${RESET}"
        fi
    done < "$FUZZ_FILE"

    wait
    echo -e "\n${YELLOW}[*] Fuzzing completed.${RESET}"
    if [ -f fuzz_results.txt ]; then
        echo -e "${GREEN}[+] Results saved in fuzz_results.txt${RESET}"
    else
        echo -e "${YELLOW}[-] No valid fuzzing results found.${RESET}"
    fi
}

if [ "$OPTION" == "subdomain" ]; then
    if [ "$#" -ne 3 ]; then
        echo -e "${RED}[!] Please provide a subdomains file for subdomain enumeration.${RESET}"
        exit 1
    fi
    enumerate_subdomains "$DOMAIN" "$OPTION" "$3"
    display_subdomain_output
elif [ "$OPTION" == "fuzz" ]; then
    if [ "$#" -ne 3 ]; then
        echo -e "${RED}[!] Please provide a fuzzing file for fuzzing.${RESET}"
        exit 1
    fi
    fuzzing "$DOMAIN" "$OPTION" "$3"
else
    echo -e "${RED}[!] Invalid option! Use 'subdomain' or 'fuzz'.${RESET}"
    exit 1
fi
