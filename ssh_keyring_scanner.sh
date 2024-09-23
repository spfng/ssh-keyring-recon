#!/bin/bash

cidr () {
	local network=(${1//\// })
	local iparr=(${network[0]//./ })
	local mask=32
	[[ $((${#network[@]})) -gt 1 ]] && mask=${network[1]}
	local maskarr
	if [[ ${mask} = '\.' ]]; then
		maskarr=(${mask//./ })
	else
		if [[ $((mask)) -lt 8 ]]; then
			maskarr=($((256-2**(8-mask))) 0 0 0)
		elif [[ $((mask)) -lt 16 ]]; then
			maskarr=(255 $((256-2**(16-mask))) 0 0)
		elif [[ $((mask)) -lt 24 ]]; then
			maskarr=(255 255 $((256-2**(24-mask))) 0)
		elif [[ $((mask)) -lt 32 ]]; then
			maskarr=(255 255 255 $((256-2**(32-mask))))
		elif [[ ${mask} == 32 ]]; then
			maskarr=(255 255 255 255)
		fi
	fi
	[[ ${maskarr[2]} == 255 ]] && maskarr[1]=255
	[[ ${maskarr[1]} == 255 ]] && maskarr[0]=255
	local bytes=(0 0 0 0)
	for i in $(seq 0 $((255-maskarr[0]))); do
		bytes[0]="$(( i+(iparr[0] & maskarr[0]) ))"
		for j in $(seq 0 $((255-maskarr[1]))); do
			bytes[1]="$(( j+(iparr[1] & maskarr[1]) ))"
			for k in $(seq 0 $((255-maskarr[2]))); do
				bytes[2]="$(( k+(iparr[2] & maskarr[2]) ))"
				for l in $(seq 0 $((255-maskarr[3]))); do
					bytes[3]="$(( l+(iparr[3] & maskarr[3]) ))"
					printf "%d.%d.%d.%d\n" "${bytes[@]}"
				done
			done
		done
	done
}

scan () {
	local port=$1
	local iter=0
	while read host; do
		iter=$(($iter + 1))
		if test "$iter" = "10"; then
			iter=0
			sleep 1
		fi
		( nc -v -n -z -w 1 $host $port && echo $host ) 2>/dev/null & disown
	done
}

main () {
	for subnet in "${@}"; do
		cidr "$subnet" | scan 80
	done
}

main "${@}"

