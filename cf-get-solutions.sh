#!/bin/bash
set -eo pipefail
useragent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.63 Safari/537.36'
[[ -z "$CF_COOKIE" ]] && CF_COOKIE=$HOME/.cf_cookie
[[ -z "$CF_CACHEDIR" ]] && CF_CACHEDIR=$HOME/.cache/cf
[[ -z "$CF_ORDER" ]] && CF_ORDER=BY_ARRIVED_DESC # BY_JUDGED_DESC
[[ -z "$CF_PAGER" ]] && CF_PAGER=(less -R)

if [[ $# -ge 2 ]]; then
	contest_id=$1
	problem_idx=${2^^}
else
	problem_idx=${PWD##*/}
	problem_idx=${problem_idx^^}
	dir=${PWD%/*}
	contest_id=${dir##*/}
fi
[[ -d "$CF_CACHEDIR" ]] || mkdir -p "$CF_CACHEDIR"
[[ ! "$contest_id" =~ ^[0-9]+$ || ! "$problem_idx" =~ ^[A-Z]$ ]] && { echo "$(basename $0) <contest_id> <ABC>"; exit 1; }
echo "[+] $contest_id $problem_idx"

for ((page=1;page<2;page++))
do
	echo "[+] Page $page"
	url="https://codeforces.com/contest/${contest_id}/status/page/${page}?order=${CF_ORDER}"
	html=$(curl -b "$CF_COOKIE" -c "$CF_COOKIE" -s -L "$url" \
	  -H 'authority: codeforces.com' \
	  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
	  -H 'accept-language: en-US,en;q=0.9;q=0.6' \
	  -H 'cache-control: max-age=0' \
	  -H 'content-type: application/x-www-form-urlencoded' \
	  -H 'origin: https://codeforces.com' \
	  -H "referer: $url" \
	  -H "$useragent" \
	  --data-raw "action=setupSubmissionFilter&frameProblemIndex=${problem_idx}&verdictName=OK&programTypeForInvoker=anyProgramTypeForInvoker&comparisonType=NOT_USED&judgedTestCount=&participantSubstring=&_tta=752" \
	  --compressed)

	page_submissions=$(echo "$html" | pup 'table.status-frame-datatable'|w3m -T text/html -dump -cols 200)
	max_lines=$(echo "$page_submissions" | wc -l)
	echo "$page_submissions" | head -1
	for ((i=2;i<=max_lines;i++))
	do
		submission_info=$(echo "$page_submissions" | sed -n ${i}p)
		[[ -z "$submission_info" ]] && exit 1
		submission_id=$(echo "$submission_info" | cut -d\  -f1)
		[[ -z "$submission_id" ]] && exit 1
		echo "$submission_info"
		read -r -p "View this submission? [Yn] " prompt
		[[ -z "$prompt" ]] && prompt=y
		[[ ! "$prompt" =~ ^[yY]$ ]] && continue
		json=${CF_CACHEDIR}/${contest_id}.${problem_idx}.${submission_id}.json
		curl -s 'https://codeforces.com/data/submitSource' \
		  -H 'authority: codeforces.com' \
		  -H 'accept: application/json, text/javascript, */*; q=0.01' \
		  -H 'accept-language: en-US,en;q=0.9' \
		  -H 'content-type: application/x-www-form-urlencoded; charset=UTF-8' \
		  -H 'origin: https://codeforces.com' \
		  -H "$url" \
		  -H "$useragent" \
		  --data-raw "submissionId=${submission_id}" \
		  --compressed -o "$json"
		lang=$(jq -r .prettifyClass "$json" | sed 's/^lang-//')
		[[ -z "$lang" ]] && lang=cpp
		src="${CF_CACHEDIR}/${contest_id}.${problem_idx}.${submission_id}.${lang}"
		jq -r .source "$json" | tr -d '\015' > "$src"
		${CF_PAGER[@]} "$src"
	done
done
