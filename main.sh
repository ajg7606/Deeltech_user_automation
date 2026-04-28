#!/usr/bin/bash
source ./scraper.sh
source ./parser.sh
source ./user_management.sh
source ./clear_users.sh
source "$(dirname "$0")/license.sh"
enforce_license

#initial decision interface
echo "Welcome. Please choose an action:"
echo "1. Make users from TNTech Computer Science faculty website"
echo "2. Delete a user from the database"
echo "3. Manually add a new user"
echo "4. Delete all CS faculty users from the database"

#input validation
while :; do
    read choice

    # Step 1: Validate it's a number
    if ! [[ "$choice" =~ ^-?[0-9]+$ ]]; then
        echo "Error: Not a valid integer."
        continue
    fi
    
    # Step 2: Validate the range
    if (( $choice >= 1 && $choice <= 4 )); then
        break
    else
        echo "Error: Number must be between 1 and 4."
    fi
done

#Option 1
if ((choice == 1)); then
	#web scraper
	result=$(scrape)

	#parser
	parse "result"
fi

#Option 2
if ((choice == 2)); then
	read -p "Who would you like to delete:" first last
	delete_user "$first" "$last"
fi

#option 3
if ((choice == 3)); then
	read -p "Who would you like to add:" first last
	create_user "$first" "$last"
fi

#option 4
if ((choice == 4)); then
	clear_users
fi
