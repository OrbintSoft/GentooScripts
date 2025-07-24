#!/bin/sh
key_dir="$HOME/.ssh"
log_file="$key_dir/sessions.log"

ssh_temp_keyctl="{SSH_TEMP_KEYCTL}"
ssh_pass_uuid="{SSH_PASS_UUID}"

log_message() {
	level="$1"
	message="$2"
    datetime=$(date '+%Y-%m-%d %H:%M:%S')
	echo "$datetime | [$level] $message" >> "$log_file"
}

log_message "INFO" "🔑 ssh-ask-pass.sh started for user $USER"

if [ -n "$ssh_temp_keyctl" ]; then
	if ! passphrase="$(keyctl print "$ssh_temp_keyctl")"; then
		log_message "ERROR" "❗ Failed to print ssh_temp_keyctl: $ssh_temp_keyctl UUID: $ssh_pass_uuid"
		exit 1
	else
		log_message "INFO" "🔑 Successfully retrieved passphrase for ssh_temp_keyctl: $ssh_temp_keyctl UUID: $ssh_pass_uuid"
	fi
	if [ -n "$passphrase" ]; then
		if ! keyctl unlink "$ssh_temp_keyctl" > /dev/null; then
			log_message "ERROR" "❗ Failed to unlink ssh_temp_keyctl: $ssh_temp_keyctl UUID: $ssh_pass_uuid"
			exit 1
		fi
		echo "$passphrase"
	else
		log_message "ERROR" "❗ Failed to retrieve passphrase for ssh_pass_uuid: $ssh_pass_uuid"
		exit 1
	fi
else
	log_message ""ERROR "❗ ssh_pass_uuid or ssh_temp_keyctl not set, cannot retrieve passphrase."
	exit 1
fi
