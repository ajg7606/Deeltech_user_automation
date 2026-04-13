#!/usr/bin/bash

scrape() {
	result=$(curl -s https://www.tntech.edu/engineering/programs/csc/faculty-and-staff.php \
	| grep -oP '(?<=<h4><strong>).*(?=</strong></h4>)' \
	| sed 's/, Ph\.D\.//g; s/&nbsp;//g; s/<\/strong><strong>//g; s/<br>//g')
	echo "$result"
}
