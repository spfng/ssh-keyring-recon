#!/usr/bin/env bash

drive_health () {
	local disk="$1"
	local temp=$(mktemp XXXXXXXXXX)
	local next="/var/www/html/drive_health/$temp"

	smartctl --all --vendorattribute="1,raw48:54" --vendorattribute="7,raw48:54" --vendorattribute="195,raw48:54" "$disk" 1>"$temp" 2>"$temp"

	error="$?"
	if test "$error" = "0"; then
		local temp_size=$(stat --format "%s" "$temp")
		local serial_number=$(cat "$temp" | awk '{if ($1 == "Serial" && ($2 == "Number:" || $2 == "number:")) { print $NF; } }')

		install -D -m 0644 -o "www-data" -g "www-data" "$temp" "$next"
	fi

	rm "$temp"
}

main () {

	# init

	if test -x "$(command -v smartctl)"; then
		:
	else
		echo "smartctl command not found"
		exit 1
	fi

	# Check disks attached to the board directly or in passthrough

	echo "Checking NVMe drives..."

	for disk in $(find "/dev" -type "b" -name "nvme?*n?*"); do
		(
		drive_health "$disk"
		) & disown
	done

	echo "Checking directly attached drives..."

	for disk in $(find "/dev" -type "b" -name "sd?*"); do
		(
		drive_health "$disk"
		) & disown
	done

	# Check disks attached to the board directly or in passthrough (BSD)

	echo "Checking directly attached drives (passthrough, BSD)..."

	for disk in $(find "/dev" -type "c" -name "pass?*"); do
		(
		drive_health "$disk"
		) & disown
	done

	# Check disks behind LSISAS2008 LV

	echo "Checking LSISAS2008 drives..."

	for disk in $(find "/dev" -type "c" -name "sg?*"); do
		(
		drive_health "$disk"
		) & disown
	done

	# Check disks behind a 3ware card

	echo "Checking 3ware drives..."

	if test -f "/dev/twl0"; then
		for index in {0..20}; do
			(
			drive_health "-d 3ware,$index /dev/twl0 -T permissive"
			) & disown
		done
	fi

	# Check scsi disks behind an lsi card - fixed at sda at the moment

	echo "Checking LSI drives..."

	if test $(command -v lspci); then
		if test "$(lspci | grep -i LSI | wc -l)" == "0"; then
			:
		else
			for index in {0..20}; do
				(
				drive_health "-d megaraid,$index /dev/sda -T permissive"
				) & disown
			done

			for index in {0..20}; do
				(
				drive_health "-d sat+megaraid,$index /dev/sda -T permissive"
				) & disown
			done
		fi
	fi

	# Check scsi disks behind an HPcard - fixed at sda at the moment

	echo "Checking HP/HPE drives..."

	for index in {0..20}; do
		(
		drive_health "-d cciss,$index /dev/sda -T permissive"
		) & disown
	done

	return 0
}

main "$@"
