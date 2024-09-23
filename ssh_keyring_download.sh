#!/bin/bash

main () {
	local iter=0
	while read host; do
		iter=$(($iter + 1))
		if test "$iter" = "10"; then
			iter=0
			sleep 1
		fi
		hash=($(sha256sum <<< "$host + password"))
		for algo in ed25519 rsa; do
			temp=$(mktemp -d)
			site="http://$host/ssh-keyring/$hash/id_$algo"
			path="$HOME/ssh-keyring/$hash"
			file="/id_$algo"
			for is_pub in "" ".pub"; do
				if curl --head --fail --output "/dev/null" --location --max-time 5 --silent $site$is_pub; then
					curl --get --fail --output "$temp$file$is_pub" --location --max-time 5 --silent --max-filesize 1K $site$is_pub
					if ssh-keygen -l -f "$temp$file$is_pub" 1>/dev/null 2>/dev/null; then
						:
					else
						rm "$temp$file$is_pub"
					fi
				fi
			done
			if test -f "$temp$file" && test -f "$temp$file.pub"; then
				install -d "$path"
				install -D -m 0600 "$temp$file" "$path$file"
				install -D -m 0644 "$temp$file.pub" "$path$file.pub"
				echo "$host"
			fi
			rm -r "$temp"
		done
	done
}

main "$@"

