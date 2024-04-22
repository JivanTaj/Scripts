#!/bin/bash
############################################################################
#	iplookup.sh
#	  Author:	    Jivan Taj 
#	  Date:		    2022-12-17
# 	  Last revised:	2023-05-07
#	  Description:	Identifies attempted hacking on the server
#			- Checks an input file for IP addresses
#			- Counts the number of attempts for each
#			- Discards IP addresses with <100 attempts
#			- Menu driven
#			  - 1. Displays IP addresses
#			  - 2. Displays detailed IP information
#			  - 3. Adds IP addresses to UFW
#			       - Makes sure IP addy isn't already in UFW
#			  - 4. Displays firewall rules
#			  - 5. Exits script
#
#     Note: READ THE COMMENTS! They're intended to act like prompts,
#           to help you navigate your way through this exercise
#
############################################################################

############### ERROR CHECKING ######################
# have to sudo to access log files
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi
# check for proper usage (correct # of arguments - 1)
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi
# check that the input file actually exists
input_file=$1
if [ ! -f "$input_file" ]; then
    echo "Input file does not exist."
    exit 1
fi
############# DONE ERROR CHECKING ##################

# variables for color text, e.g.,
RESET="\e[0m"  #reset color to default (you can Google the rest)

################### VARIABLES ######################
#input_file=$1 (moved for error checking purposes)
input="1"
printCounter="0"
attempts="0"
uniqueIPs="0"

################## REGEX VARS #######################
sec="(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])" #this regex breaks the IP address into 4 sections 
ip="\b$sec\.$sec\.$sec\.$sec\b" #this matches IPs with 4 valid sections only 

################## Regualr expressions ######################
#regs gets all offending ips + attempts, and acts as a base for regex 
regs="$(grep -Eo "rhost=$ip" $input_file | sort | uniq -c | awk '{if ($1 >= 100) print $0}' | sed 's/rhost=//g')" 
#regsInfo adds formatting to the display 
regsInfo=$(echo "$regs" | awk '{print "IP: " $2 "\t Attempts: " $1}')
#regsIP gets just the ips, trimming attempt count
regsIP=$(echo "$regs" | awk '{print $2}')

################# Functions #########################
# Function to get all offenders
function get_all_offenders() {
    echo "$regsIP"
}
#display the unique IP addresses on demand
function display_unique_ips () {
    echo "$regsInfo"
}
#print detailed info on the offenders
function print_info () {
    uniqueIPs=$(display_unique_ips | awk '{print $2}')
    for val in $uniqueIPs; do
        #iteration control
        printCounter=$((printCounter + 1))
        #printed information 
        echo
        echo -e "IP: $val"
        attempts=$(grep -E "IP: $val" <<< "$regsInfo" | awk '{print $NF}')
        echo "Attempts: $attempts"
        curl "ipinfo.io/${val}?token=ed7c379ba31576"
        echo -e "  Last Attempt: $(grep $val $input_file | tail -n1 | cut -d' ' -f1-4)"
        echo
        #pause logic block 
        if [ $((printCounter % 2)) -eq 0 ]; then
            read -n 1 -s -p "Press any key to continue or L to exit..." input
            echo
            if [ "$input" == "L" ] || [ "$input" == "l" ]; then
                break
            fi
        fi
    done
}
#add the IPs to the firewall.
function add_ips_to_ufw {
    offenders=$(get_all_offenders)
    for ip in $offenders; do
        if ufw status | grep -q $ip; then
            echo "IP address $ip is already in UFW."
        else
            echo "Adding IP address $ip to UFW..."
            sudo ufw deny from $ip
        fi
    done
}
#this'n's easy...
function show_firewall () {
    ufw status numbered
}

################## Summary Counts ##############################
#total attempts
totalAttempts=$(echo "$regs" | awk '{sum += $1} END {print sum}')
#total unique IPs
totalUniqueIPs=$(echo "$regs" | wc -l)
#print summary info pre-menu 
echo -e "\t\nDiscovered $totalAttempts suspicious login attempts from $totalUniqueIPs unique IP addresses."

################## Menu ###############################
# the menu function 
function menuDriver() {
    case $input in 
        1) echo "Displaying unique IP addresses:"; display_unique_ips ;;
        2) echo "Printing detailed information on offenders:"; print_info ;;
        3) echo "Adding IP addresses to UFW:"; add_ips_to_ufw ;;
        4) echo "Showing firewall rules:"; show_firewall ;;
        5) echo "Done! Bye now"; exit 0 ;;
        *) echo "Invalid input. Please try again." ;;
    esac
}

## menu while statement 
while [[ $input != 5 ]]; do
    echo -e "\nMenu:"
    echo "1. Display unique IP addresses"
    echo "2. Print detailed information on offenders"
    echo "3. Add IP addresses to UFW"
    echo "4. Show firewall rules"
    echo "5. Exit"
    read -p "Enter your choice (1-5): " input 
    echo -e "\n\n"
    menuDriver
done


###################################################################
