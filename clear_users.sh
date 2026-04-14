#!/usr/bin/bash

source ./scraper.sh
source ./user_management.sh

clear_users() {
	names=$(scrape)


	while read -r line; do
		first=$(echo "$line" | awk '{print $1}')
        	last=$(echo "$line" | awk '{print $NF}')
        	delete_user "$first" "$last"
	done <<< "$names"
}
