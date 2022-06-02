#!/bin/bash
[[ -z "$CF_LIST" ]] && CF_LIST=$HOME/.cf_list
[[ -z "$CF_SRC_DIR" ]] && CF_SRC_DIR=$HOME/CF_SOLVED
CF_START=A; CF_END=D
[[ ! -z "$CF_LEVEL" ]] && { CF_LEVEL=${CF_LEVEL^^}; CF_START=${CF_LEVEL%%-*}; CF_END=${CF_LEVEL##*-}; }

list_contests() {
	[[ -f "$CF_LIST" ]] || { echo "[!] list not found"; exit 1; }
	while read line
	do
		[[ -z "$line" ]] && exit 1;
		nr=$(echo "$line"|cut -d. -f1)
		msg=""
		count=0
		for d in `eval echo {$CF_START..$CF_END}`
		do
			[[ -f "${CF_SRC_DIR}/${nr}${d,}.cpp" ]] && msg+="  " || { msg+=" $d"; ((count++)); }
		done
		[[ $count -gt 0 ]] && echo "$nr $msg ${line#*.}" || ((solved++))
	done < <(cat "$CF_LIST" | tac)
	[[ -z "$solved" ]] && solved=0
	echo "[*] Solved $solved contests"
}
if [[ $# -eq 0 ]]; then
	list_contests
	exit 0
fi
cfpage=$1
[[ $cfpage =~ ^[0-9]+$ ]] || { echo "[!] argument is not numeric"; exit 0; }
[[ $# -gt 1 && "$2" =~ ^[0-9]+$ ]] && cflevel=$2

[[ -f "$CF_LIST" ]] && cp -v "$CF_LIST" "${CF_LIST}.bck"
for i in `eval echo {$cfpage..1}`
do
	if [[ -z "$cflevel" ]]; then
		curl -Ls "https://codeforces.com/contests/page/$i" | pup 'tr[data-contestid] td:nth-child(1)' | grep -B2 ' href="[^"]*[0-9]"' | sed 's/^\s*//;/^<br>$/d;/^--$/d;s/.* href="\/contest\/\([^"]*\)">/\1./' | awk '{getline x; print x}1' | paste -d " " - - | tac >> "$CF_LIST"
	else
		curl -Ls "https://codeforces.com/contests/page/$i" | pup 'tr[data-contestid] td:nth-child(1)' | grep -B2 ' href="[^"]*[0-9]"' | sed 's/^\s*//;/^<br>$/d;/^--$/d;s/.* href="\/contest\/\([^"]*\)">/\1./' | awk '{getline x; print x}1' | paste -d " " - - | tac | grep "Div\. $cflevel" >> "$CF_LIST"
	fi
	sleep 0.5
done

mv "$CF_LIST" "${CF_LIST}.tmp"
sort "${CF_LIST}.tmp" | uniq > "${CF_LIST}"
rm "${CF_LIST}.tmp"
list_contests
