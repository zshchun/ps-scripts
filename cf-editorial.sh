#!/bin/bash
useragent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.63 Safari/537.36'
[[ -z "$CF_COOKIE" ]] && CF_COOKIE=$HOME/.cf_cookie
[[ -z "$CF_LIST" ]] && CF_LIST=$HOME/.cf_list

if [[ $# -ge 1 ]]; then
	contest_id=$1
else
	dir=${PWD%/*}
	contest_id=${dir##*/}
fi

[[ ! "$contest_id" =~ ^[0-9]+$ ]] && { echo "$(basename $0) <contest_id> <ABC>"; exit 1; }
echo "[+] $contest_id"
round=$(cat "$CF_LIST" | grep "^$contest_id" | grep -iao "round #\?[0-9]\+" | tr -dc \#0-9)
[[ -z "$round" ]] && exit 1;

test_page=$(curl -Ls -b "$CF_COOKIE" -H "user-agent: $useragent" "https://codeforces.com/contests")

if [[ "$test_page" =~ RCPC= ]]; then
	echo "[+] RCPC token detected"
	ciphertext=$(echo "$test_page" | grep -ao 'c=toNumbers("[^"]*' | cut -d\" -f2)
	key=$(echo "$test_page" | grep -ao 'a=toNumbers("[^"]*' | cut -d\" -f2)
	iv=$(echo "$test_page" | grep -ao 'b=toNumbers("[^"]*' | cut -d\" -f2)
	rcpc=$(echo -n "$ciphertext" | xxd -r -p | openssl enc -aes-128-cbc -d -K "$key" -iv "$iv" -nopad | xxd -ps -c32)
	[[ -z "$rcpc" ]] && exit 1
	sed -i '/RCPC/d' "$CF_COOKIE"
	echo -e "codeforces.com\tFALSE\t/\tFALSE\t0\tRCPC\t$rcpc" >> "$CF_COOKIE"
fi

url="https://codeforces.com/search"
html=$(curl -b "$CF_COOKIE" -s -L "$url" \
  -H 'authority: codeforces.com' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H 'cache-control: max-age=0' \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'origin: https://codeforces.com' \
  -H 'referer: https://codeforces.com/' \
  -H "user-agent: $useragent" \
  --data-urlencode "query=title:editorial ${round}" \
  --compressed)
titles=$(echo "$html" | pup 'div.content div.highlights' | sed 's/<[^>]*>//g;s/^\s*//;/^$/d;')
links=$(echo "$html" | pup 'div.content a attr{href}' | grep '/blog/entry/[0-9]*')
total_lines=$(echo "$title" | wc -l)
for ((i=1;i<=total_lines;i++))
do
	title=$(echo "$titles" | sed -n ${i}p)
	link=$(echo "$links" | sed -n ${i}p)
	echo "$title : https://codeforces.com${link}"
done
