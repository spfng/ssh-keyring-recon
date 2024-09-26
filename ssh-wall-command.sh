#!/bin/bash

main () {
	case "$@" in
		"@"*) script_file="${1:1}" ; shift ;;
	esac
	while read host; do
		hash=($(sha256sum <<< "$host + password"))
		for algo in ed25519 rsa; do
			path="$HOME/.ssh-wall/known_hosts/$hash"
			file="/id_$algo"
			if test -f "$path$file"; then
				identity_file="$path$file"
			fi
		done
		if test -f "$identity_file"; then
			proc="$(mktemp -d proc.XXXXXXXXXX)"

			(
			if test -f "$script_file"; then
				ssh -i "$identity_file" -o "StrictHostKeyChecking=no" "root@$host" "bash -s" -- < "$script_file" "$@" &
				pid="$!"
			else
				ssh -i "$identity_file" -o "StrictHostKeyChecking=no" "root@$host" "$@" &
				pid="$!"
			fi
			echo "$pid" > "$proc/pid"
			wait "$pid"
			echo "$?" > "$proc/exit"
			) 1>"$proc/stdout" 2>"$proc/stderr" & disown

			(
			until test -f "$proc/pid"; do
				sleep 1
			done
			until test -f "$proc/exit"; do
				if test -f "$proc/kill-15"; then
					kill -15 "$(< $proc/pid)"
				fi
				if test -f "$proc/kill-9"; then
					kill -9 "$(< $proc/pid)"
				fi
				sleep 1
			done
			rm -r "$proc"
			) & disown

			unset proc pid
			unset path file identity_file script_file
			unset host
		fi
	done
}

main "$@"

