#!/usr/bin/bash
source ./scraper.sh
source ./parser.sh
source ./user_management.sh
source "$(dirname "$0")/license.sh"
#enforce_license

#initial decision interface
echo "Welcome. Please choose an action:"
echo "1. Make users from TNTech Computer Science faculty website"
echo "2. Delete a user from the database"
echo "3. Manually add a new user"
read choice

#input validation


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
