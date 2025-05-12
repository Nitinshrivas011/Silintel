#!/bin/bash
#####PROGRESS_BAR######
progress_bar() {
    local pid=$1
    local status=$2
    local total_ticks=50
    local interval=0.2
    local spinstr='|/-\\'
    local i=0
    local start_time=$(date +%s)

    # Loop until the process is finished
    while kill -0 $pid 2>/dev/null; do
        # Calculate elapsed time in seconds
        elapsed_time=$(( $(date +%s) - start_time ))

        # Estimate progress based on elapsed time and the total duration
        progress=$(( elapsed_time * total_ticks / 60 ))  # Assuming it takes ~60 seconds max
        if [ $progress -gt $total_ticks ]; then
            progress=$total_ticks
        fi

        # Spinner animation
        i=$(( (i+1) %4 ))
        printf "\r[ ${spinstr:i:1} ] ${2}: ["
        
        # Print progress bar
        for ((j=0; j<total_ticks; j++)); do
            if (( j < progress )); then
                printf "="
            else
                printf " "
            fi
        done
        printf "] %d%%" $(( progress * 100 / total_ticks ))

        sleep $interval
    done

    # When Sherlock finishes, mark progress as 100%
    printf "\r[✔] ${2}: ["
    for ((j=0; j<total_ticks; j++)); do
        printf "="
    done
    printf "] 100%% Done!               \n"
}

process_progress(){
	local status=$1
	pid=$!
	progress_bar $pid $status
	wait $pid
}

#######################

# Function to display status menu
status_menu() {
	printf "\n\nChoose option to filter out the live URLs:\n"
    echo "1. Live URLs"
    echo "2. Custom regex"
    echo "3. Go back to main menu"
}

handle_status_input() {
	local user_choice=$1
    local choice
	    read -p "Enter your choice [1-3]: " choice

    case $choice in
        1)
            # Live URLs
            cat output/username/${user_choice}.txt | grep -i "200" | sort | uniq
            ;;
        2)
            # Custom regex
            local custom_choice
            	read -p "Enter custom regex: " custom_choice
            cat output/username/${user_choice}.txt | grep  -Eo "${custom_choice}" | sort | uniq
            ;;
		3)
			# Main menu
			show_menu
			handle_input
			;;
        *)
            # Invalid choice
            echo "Invalid choice. Please try again."
            ;;
    esac
}

#Function to find username
username() {
	clear -x
	echo "U S E R N A M E   -X-   F I N D E R" | figlet -tc -f mini | lolcat
	local choice
	    read -p "Enter a username you want to find [example123]: " choice
	
	## Using Sherlock to enumerate user
	sherlock $choice --output output/username/${choice}.txt > /dev/null 2>&1 &
	# Progress bar
	process_progress "Finding_username"

	#Filter out the result on the basis of their status code
	cat ./output/username/${choice}.txt | httpx -sc -title -duc -follow-redirects -o output/username/${choice}.txt > /dev/null 2>&1 &
	process_progress "Filtering_live_URLs"
	
	#Open status menu
	while true; do
		status_menu
		handle_status_input $choice
	done
}

#Function to DNS Lookup
dns_lookup() {
	clear -x
	echo "D N S   -X-   L O O K U P" | figlet -tc -f mini | lolcat
	local choice
	    read -p "Enter a domain to lookup [example.com]: " choice
	
	#Finding DNS lookup using custom regex
	dig $choice >> output/domain/${choice}.txt
	nslookup $choice >> output/domain/${choice}.txt
	whois $choice >> output/domain/${choice}.txt
	
	cat output/domain/${choice}.txt | sort | uniq
	
}

#Function to find Company Emails
email_finder() {
	clear -x
	echo "E M A I L   -X-   F I N D E R" | figlet -tc -f mini | lolcat
	local choice
	    read -p "Enter company domain you want to find email [example.co.in]: " choice
	
	#Finding Email by filtering out with custom regex
	CONFIG_FILE="config.json"

	# Load API key from config.json
	if [ ! -f "$CONFIG_FILE" ]; then
  		echo "Error: Config file $CONFIG_FILE not found!"
  		exit 1
	fi

	API_KEY=$(jq -r '.api_key' "$CONFIG_FILE")

	if [ "$API_KEY" == "null" ] || [ -z "$API_KEY" ]; then
  		echo "Error: API key not found in $CONFIG_FILE"
  		exit 1
	fi

	DOMAIN=$choice

	echo "Searching for emails at $DOMAIN ..."
	

	response=$(curl -s "https://api.hunter.io/v2/domain-search?domain=$DOMAIN&api_key=$API_KEY")
	process_progress "Searching_emails"
	# Check for API error
	if echo "$response" | jq -e '.errors' > /dev/null; then
  		echo "Error: $(echo "$response" | jq '.errors')"
  		exit 1
	fi

	# Extract emails
	emails=$(echo "$response" | jq -r '.data.emails[].value')

	if [ -z "$emails" ]; then
  		echo "No emails found for $DOMAIN"
	else
  		echo "Emails found:"
  		echo "$emails"
	fi
	
}

##Function to check user opt for specific port or not
isPort() {
  local option
  read -p "Enter [0] for _default or [1] for custom: " option
	
  if [ "$option" -eq 1 ]; then
  	local range
  		read -p "Enter port range between [1-65535] or comma-seperated port value [80,8080]: " range
    echo "-p $range"
  elif [ "$option" -eq 0 ]; then
    echo ""
  else
    echo "Invalid option"
  fi
}

# Function to scan a domain using nmap
nmap_Scan() {
 	local domain=$1
 	shift  # Shift the first argument (domain)
 	local port="$@"  # The rest are port options

 	nmap "$domain" $port -oN output/scans/${domain}.txt > /dev/null 2>&1 &
 	process_progress "Scanning"
 	##Showing result
 	echo -e "\n"
 	PATTERNS=("[0-9]{1,3}(\.[0-9]{1,3}){3}: [a-zA-Z0-9.-]+" "[0-9]{1,5}/[A-Za-z]+[[:space:]]*")
 	for pattern in $PATTERNS; do
 		cat ./output/scans/${domain}.txt | grep --color=always -E "$pattern" | uniq
 	done
 	#cat ./output/scans/${domain}.txt | grep --color=always -E "[0-9]{1,5}+/[A-Za-z]+[[:space:]]*"
 	if ! grep --color=always -E "[0-9]{1,5}/[A-Za-z]+[[:space:]]*" "./output/scans/${domain}.txt"; then
 		echo "No match found!"
	fi
}

#Function to sCAN pORTS
scan_port() {
	clear -x
	echo "A C T I V E   -X-   P O R T   -X-   S C A N N I N G" | figlet -tc -f mini | lolcat
	local choice
	    read -p "Enter IP/s or domain/s to scan live ports: " choice
	
	#Scanning live ports
	DOMAIN=$choice
	printf "\n\nChoose your scanning technique [1-7]:\n"
    echo "1. Stealth Scan"
    echo "2. TCP Connect Scan"
    echo "3. TCP NULL Scan"
    echo "4. Xmas Scan"
    echo "5. UDP Scan"
    echo "6. Custom Scan"
    echo "7. Exit"
    
	local option
	    read -p "Enter your choice [1-5]: " option

    case $option in
        1)
            # Stealth Scan
            nmap_Scan "$DOMAIN" -sS "$(isPort)" #isIPspoof isVerbose isAggressive isVersionDetect 
            ;;
        2)
            # TCP Connect Scan
            nmap_Scan "$DOMAIN" -sT "$(isPort)"
            ;;
        3)
            # TCP NULL Scan
            nmap_Scan "$DOMAIN" -sN "$(isPort)"
            ;;
        4)
            # Xmas Scan
            nmap_Scan "$DOMAIN" -sX "$(isPort)"
            ;;
        5)
            # UDP Scan
            nmap_Scan "$DOMAIN" -sU "$(isPort)"
            ;;
        6)
            # Custom Scan
            nmap_Scan "$DOMAIN"
            ;;
        7)
            # Exit the script
            echo "Exiting the script"
            exit 0
            ;;
        *)
            # Invalid choice
            echo "Invalid choice. Please try again."
            ;;
    esac
	
}

# Function to display the menu
show_menu() {
    printf "\n\nChoose your option:\n"
    echo "1. Username Finder"
    echo "2. DNS Lookup"
    echo "3. Email Finder"
    echo "4. Port Scanning (Active Reconn)"
    echo "5. Exit"
}

# Function to handle user input
handle_input() {
    local choice
	    read -p "Enter your choice [1-5]: " choice

    case $choice in
        1)
            # Username Finder
            username
            ;;
        2)
            # Code for Option 2
            dns_lookup
            ;;
        3)
            # Code for Option 3
            email_finder
            ;;
        4)
            # Code for Option 5
            scan_port
            ;;
        5)
            # Exit the script
            echo "Exiting the script"
            exit 0
            ;;
        *)
            # Invalid choice
            echo "Invalid choice. Please try again."
            ;;
    esac
}

#### Return random font for the banner
get_random_value() {
    local arr=("$@")
    local random_index=$((RANDOM % ${#arr[@]}))
    echo "${arr[$random_index]}"
}
array=("bubble" "shadow" "big" "banner" "script" "lean" "ivrit" "smslant")
random_value=$(get_random_value "${array[@]}")

#### Main script execution starts here
figlet "Silintel" -tc -f $random_value | lolcat
#figlet "_by Nitin" -tr -f digital | lolcat
echo "Welcome to my OSINT world. THE tooL prOvidE yOu a SimplE InterFace tO hUnt dOwn yOur targEts anD knoW youR lEakEd DaTa On thE WEb!  As you know 'WiTh grEat pOwers cOmeS grEat rEspOnsibilTy :)'" | figlet -f term -tc

##creating an output directory

while true; do
	show_menu
    handle_input
done
