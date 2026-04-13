#!/usr/bin/bash
source ./user_management.sh

parse() {
	while read -r line; do
		first=$(echo "$line" | awk '{print $1}')
		last=$(echo "$line" | awk '{print $NF}')
		create_user "$first" "$last"
	done <<< "$result"
}
