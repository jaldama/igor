#!/bin/bash

# Path to your config file
CONFIG_FILE=".lab.cfg"

# Function to read values from the config file
read_config() {
    if [[ ! -f "$HOME/$CONFIG_FILE" ]]; then
        echo "Error: Config file $CONFIG_FILE not found!"
        exit 1
    fi

    while IFS='=' read -r key value; do
        if [[ -n "$key" && ! "$key" =~ ^# ]]; then
            value=$(echo "$value" | xargs)
            export "$key"="$value"
        fi
    done < "$CONFIG_FILE"
}

# Function one: Extend reservation
extend_reservation() {
    echo "Extending reservation for Lab $labnum..."

    curl -s "${labapiaddress}/reservation?lab=opsmgr${labnum}-${labdomain}&request=extend" \
         -H 'Accept: application/json, text/plain, */*' \
         -H "Authorization: Basic ${labauth}" \
         -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryfIrWHjxvbxARPwBN' \
         --data-raw $'------WebKitFormBoundaryfIrWHjxvbxARPwBN\r\nContent-Disposition: form-data; name="file"\r\n\r\n{"lab":"opsmgr'"${labnum}"$'-'"${labdomain}"$'","shared":false,"labDescription":"Private Lab","owner_name":"'"${labownername}"$'","owner_email":"'"${labowneremail}"$'","startOfReservationDate":"2025-01-27","endOfReservationDate":"2025-02-10","lastReservationModificationDate":"2025-01-27","purpose":"'"${labpurpose}"$'","numberOfRenews":0,"timezone":"","allow_deploy":true,"active":true,"labNumber":'"${labnum}"$',"slotNumber":'"${labslot}"$',"nuked":false}\r\n------WebKitFormBoundaryfIrWHjxvbxARPwBN--\r\n' \
         --insecure | jq .
}


# Function two: Reserve lab
reserve_lab() {
    echo "Reserving lab for Lab $labnum..."

    curl -s "${labapiaddress}/reservation?lab=opsmgr${labnum}-${labdomain}&request=reserve" \
         -H 'Accept: application/json, text/plain, */*' \
         -H "Authorization: Basic ${labauth}" \
         -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryfIrWHjxvbxARPwBN' \
         --data-raw $'------WebKitFormBoundaryfIrWHjxvbxARPwBN\r\nContent-Disposition: form-data; name="file"\r\n\r\n{"lab":"opsmgr'"${labnum}"$'-'"${labdomain}"$'","shared":false,"labDescription":"Private Lab","owner_name":"'"${labownername}"$'","owner_email":"'"${labowneremail}"$'","startOfReservationDate":"2025-01-27","endOfReservationDate":"2025-02-10","lastReservationModificationDate":"2025-01-27","purpose":"'"${labpurpose}"$'","numberOfRenews":0,"timezone":"","allow_deploy":true,"active":false,"labNumber":'"${labnum}"$',"slotNumber":'"${labslot}"$',"nuked":false}\r\n------WebKitFormBoundaryfIrWHjxvbxARPwBN--\r\n' \
         --insecure | jq .
}


# Function three: Find my lab
find_my_lab() {
    curl -s "${labapiaddress}/owner" -H "Authorization: Basic ${labauth}" | jq "with_entries(select(.value.owner_name == \"${labownername}\"))"
}


lab_status() {
    curl -s "${labapiaddress}/owner" -H "Authorization: Basic ${labauth}" | jq 'to_entries | sort_by(.value.endOfReservationDate) | reverse | from_entries'
}

get_lab() {
    curl -s "${labapiaddress}/products" -H "Authorization: Basic ${labauth}" | jq "with_entries(select(.value.LabNum == ${labnum}))" | sed 's/"SshKey": "/"SshKey": "\n/g' | sed 's/\\n/\n/g'
}

# Main function to parse CLI arguments
main() {
    # Read the config file
    read_config

    # Check for flags to decide which function to call
    while getopts "erflg" opt; do
        case $opt in
            e)
                extend_reservation
                ;;
            r)
                reserve_lab
                ;;
            f)
                find_my_lab
                ;;
            l)
                lab_status
                ;;
            g)
                get_lab
                ;;
            *)
                echo "Usage: $0 [-e] to extend reservation, [-r] to reserve lab, [-f] to find current reservation"
                exit 1
                ;;
        esac
    done
}

# Call the main function
main "$@"
