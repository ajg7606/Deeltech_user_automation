#!/usr/bin/bash

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
