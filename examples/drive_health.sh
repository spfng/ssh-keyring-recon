#!/usr/bin/env bash

drive_health () {
	local disk="$1"
	local temp=$(mktemp XXXXXXXXXX)
	local next="/var/www/html/ready/$temp"

	smartctl --all --vendorattribute="1,raw48:54" --vendorattribute="7,raw48:54" --vendorattribute="195,raw48:54" "/dev/$disk" 1>"$temp" 2>"$temp"

	error="$?"
	if test "$error" = "0"; then
		local temp_size=$(stat --format "%s" "$temp")
		local serial_number=$(cat "$temp" | awk '{if ($1 == "Serial" && ($2 == "Number:" || $2 == "number:")) { print $NF; } }')

		echo "X-Page-Title: Disk $serial_number assigned to $disk" | cat - "$temp" | tee "$temp"
		echo "X-Page-Size: $temp_size" | cat - "$temp" | tee "$temp"
		echo "" | cat - "$temp" | tee "$temp"

		install -D -m 0644 -o "www-data" -g "www-data" "$temp" "$next"

		echo "$next"
	fi

	rm "$temp"
}

main () {
	if test -x "$(command -v smartctl)"; then
		:
	else
		echo "smartctl command not found"
		exit 1
	fi

	for disk in $(lsblk --include 8,259 --nodeps --bytes --output KNAME --noheadings); do

		uploaded_file=$(drive_health "$disk")

	done

	return "$error"
}

main "$@"
