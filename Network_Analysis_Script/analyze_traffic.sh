#!/bin/bash

# -------------------------------------------------- Functions -------------------------------------------------#
#################################################################################################################

function getPacketsNumber () 
{
    declare PCAP_FILEPATH="$1"
    declare TARGET_STRING=""
    declare DIRECTORY_PATH=""
    declare PACKET_NUMBER=0
    declare -i COUNTER=0

    DIRECTORY_PATH="${PCAP_FILEPATH%/*}"
    touch "${DIRECTORY_PATH}/output.txt"
    capinfos -c "${PCAP_FILEPATH}" > "${DIRECTORY_PATH}/output.txt"
    while IFS= read -r line; do
        COUNTER=$((COUNTER + 1))
        if (( COUNTER == 2 )); then
            TARGET_STRING="${line}"
        fi
    done < "${DIRECTORY_PATH}/output.txt"

    rm "${DIRECTORY_PATH}/output.txt"

    trimmed=$(echo -e "${TARGET_STRING}" | tr -d '[:space:]')
    PACKET_NUMBER="${trimmed#*:}"

    echo "$PACKET_NUMBER"
}

function getTLSPacketsNumber () {
    declare PCAP_FILEPATH="$1"
    declare DIRECTORY_PATH=""
    declare -i TLS_NUMBER=0

    DIRECTORY_PATH="${PCAP_FILEPATH%/*}"
    touch "${DIRECTORY_PATH}/output.txt"
    tshark -r "${PCAP_FILEPATH}" -Y tls -T text > "${DIRECTORY_PATH}/output.txt"
    while IFS= read -r line; do
        TLS_NUMBER=$((TLS_NUMBER + 1))
    done < "${DIRECTORY_PATH}/output.txt"

    rm "${DIRECTORY_PATH}/output.txt"

    echo $TLS_NUMBER
}

function getHTTPPacketsNumber () {
    declare PCAP_FILEPATH="$1"
    declare DIRECTORY_PATH=""
    declare -i HTTP_NUMBER=0

    DIRECTORY_PATH="${PCAP_FILEPATH%/*}"
    touch "${DIRECTORY_PATH}/output.txt"
    tshark -r "${PCAP_FILEPATH}" -Y http -T text > "${DIRECTORY_PATH}/output.txt"
    while IFS= read -r line; do
        HTTP_NUMBER=$((HTTP_NUMBER + 1))
    done < "${DIRECTORY_PATH}/output.txt"

    rm "${DIRECTORY_PATH}/output.txt"

    echo $HTTP_NUMBER
}

function getTopSourceIPs () {
    declare PCAP_FILEPATH="$1"
    declare DIRECTORY_PATH=""
    declare IP_ADDRESS=""
    declare -i NUMBER=0
    declare -i PACKETS=0

    DIRECTORY_PATH="${PCAP_FILEPATH%/*}"
    touch "${DIRECTORY_PATH}/src_ips.txt"
    touch "${DIRECTORY_PATH}/counts.txt"
    tshark -r "${PCAP_FILEPATH}" -T fields -e ip.src | sort > "${DIRECTORY_PATH}/src_ips.txt"
    cat "${DIRECTORY_PATH}/src_ips.txt" | sort | uniq -c | sort -nr > "${DIRECTORY_PATH}/counts.txt"

    while IFS= read -r line; do
        NUMBER=$((NUMBER + 1))
        trimmed=$(echo -e "${line}" | sed -e 's/^[[:space:]]*//')
        IP_ADDRESS="${trimmed#* }"
        PACKETS="${trimmed% *}"
        echo "${IP_ADDRESS}: ${PACKETS} packets sent"
        if (( NUMBER == 5 )); then
            break
        fi
    done < "${DIRECTORY_PATH}/counts.txt" 

    rm "${DIRECTORY_PATH}/src_ips.txt" "${DIRECTORY_PATH}/counts.txt"
}

function getTopDestinationIPs () {
    declare PCAP_FILEPATH="$1"
    declare DIRECTORY_PATH=""
    declare IP_ADDRESS=""
    declare -i NUMBER=0
    declare -i PACKETS=0

    DIRECTORY_PATH="${PCAP_FILEPATH%/*}"
    touch "${DIRECTORY_PATH}/dst_ips.txt"
    touch "${DIRECTORY_PATH}/counts.txt"
    tshark -r "${PCAP_FILEPATH}" -T fields -e ip.dst | sort > "${DIRECTORY_PATH}/dst_ips.txt"
    cat "${DIRECTORY_PATH}/dst_ips.txt" | sort | uniq -c | sort -nr > "${DIRECTORY_PATH}/counts.txt"

    while IFS= read -r line; do
        NUMBER=$((NUMBER + 1))
        trimmed=$(echo -e "${line}" | sed -e 's/^[[:space:]]*//')
        IP_ADDRESS="${trimmed#* }"
        PACKETS="${trimmed% *}"
        echo "${IP_ADDRESS}: ${PACKETS} packets received"
        if (( NUMBER == 5 )); then
            break
        fi
    done < "${DIRECTORY_PATH}/counts.txt"

    rm "${DIRECTORY_PATH}/dst_ips.txt" "${DIRECTORY_PATH}/counts.txt"
}
#################################################################################################################

# ---------------------------------------------------- Main ----------------------------------------------------#
#################################################################################################################

function main () {
    declare pcap_filepath="$1"
    declare packets_number=0
    declare -i http_packets=0
    declare -i tls_packets=0
    declare -i arg_num="$#"

    if (( arg_num != 1 )); then
        echo "Invalid number of arguments, please provide the path of a .pcap file e.g: /path/to/filename.pcap"
        exit 1
    fi
    if [ ! -f "${pcap_filepath}" ]; then
        echo "The file ${pcap_filepath} doesn't exist"
        exit 2
    fi
    
    packets_number="$(getPacketsNumber "${pcap_filepath}")"
    http_packets=$(getHTTPPacketsNumber "${pcap_filepath}")
    tls_packets=$(getTLSPacketsNumber "${pcap_filepath}")

    printf "%s\n\n" "Total number of captured packets in the file: ${pcap_filepath} = ${packets_number}"
    printf "%s\n\n" "Number of packets that use the http protocol = ${http_packets}"
    printf "%s\n\n" "Number of packets that use the https(tls) protocol = ${tls_packets}"

    printf "%s\n\n" "Top five source IP addresses : "
    getTopSourceIPs "${pcap_filepath}"

    printf "\n"

    printf "%s\n\n" "Top five destination IP addresses : "
    getTopDestinationIPs "${pcap_filepath}"

    exit 0
}

main "$1"