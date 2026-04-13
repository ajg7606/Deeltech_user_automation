#!/usr/bin/bash

create_user() {

	first=$(echo "$1" | tr -d ',')
	last=$(echo "$2" | tr -d ',')
#Makes names lowercase
	first=$(echo "$first" | tr '[:upper:]' '[:lower:]')
	last=$(echo "$last" | tr '[:upper:]' '[:lower:]')
#Creates username and password
	username="${first}.${last}"
	password="${first}${last}DEELTECH"
#Checks if username is in use
	if id "$username" &>/dev/null; then
		echo "[INFO] User $username already exist. Skipping them."
		return
	fi
#Create Ubuntu user with the home directory and bash shell
	sudo useradd -m -s /bin/bash "$username"
#Set password in chpasswd
	echo "$username:$password" | sudo chpasswd
#Force change password on the first login
	sudo chage -d 0 "$username"

	echo "[SUCCESS] Created user: $username"
}

delete_user() {
        first=$(echo "$1" | tr -d ',')
        last=$(echo "$2" | tr -d ',')
        first=$(echo "$first" | tr '[:upper:]' '[:lower:]')
        last=$(echo "$last" | tr '[:upper:]' '[:lower:]')
        username="${first}.${last}"

        if ! id "$username" &>/dev/null; then
                echo "[INFO] User $username does not exist. Skipping."
                return
        fi

        sudo userdel -r "$username" >/dev/null 2>&1
        echo "[SUCCESS] Deleted user: $username"
}
