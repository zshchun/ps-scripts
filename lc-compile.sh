#!/bin/bash
if [ $# -lt 2 ]; then
	echo "Usage : $0 [-x] [-r] <solution> <testcase> [answer]"
	echo "   -x : execute test file after compile"
	echo "   -r : remove test files"
	exit 2
fi
execute=0
delete=0

while [ "$1" == "-x" ] || [ "$1" == "-r" ]
do
	case "$1" in
	"-x") execute=1; shift; ;;
	"-r") delete=1; shift; ;;
	esac
done

[[ -z "$CXX" ]] && CXX="clang++"
[[ -z "$CPPFLAGS" ]] && CPPFLAGS="-std=c++17"

solution=$(realpath "$1")
testcase=$(realpath "$2")
[[ -f "$testcase" ]] || { echo "[!] test data file not found"; exit 1; }
[[ -f "$solution" ]] || { echo "[!] solution file not found"; exit 1; }
[[ $# -ge 3  && -f "$3" ]] && answer=$3
[[ -z "$test_bin" ]] && test_bin=$(mktemp -u)
test_src=${test_bin}.cpp
test_ans=${test_bin}.ans
method_decl=$(cat "$solution" | grep -A1 '^public:' | tail -1 | sed 's/{$//;s/^\s*//;s/&//g')
[[ -z "$method_decl" ]] && { echo "[!] failed to parse $solution"; exit 1; }
ret_type=$(echo "$method_decl" | cut -d\  -f1)
method_name=$(echo "$method_decl" | cut -d\  -f2 | cut -d\( -f1)
full_args=$(echo "$method_decl" | sed 's/[^(]*(\([^)]*\))/\1/')

[[ -x $(which "$CXX") ]] || { echo "[!] compiler not found"; exit 1; }
testcase_max=$(grep -c "" "$testcase")
[[ $testcase_max -eq 0 ]] && { echo "[!] test data is empty"; exit 1; }

echo "[+] Compile $solution with $test_src"
#declare_struct=""
#grep -q ' * struct' "$solution" && echo "struct detected" && declare_struct=$(grep -E '^ \* (struct|\s|\})' "$solution" | sed 's/^ \* //')
arg_idx=1
loop_idx=1

declare_arguments=""
declare_answer=""

[[ -z "$answer" ]] && compare_answer="" || compare_answer="cout << endl;"
while [[ $arg_idx -le $testcase_max ]]
do
	input_data=""
	method_arguments=""
	while read arg
	do
		[[ $arg_idx -gt $testcase_max ]] && { echo "[!] argument does not match with testcase data"; exit 1; }
		arg_type=$(echo "$arg" | cut -d\  -f1)
		arg_name=$(echo "$arg" | cut -d\  -f2)
		arg_data=$(cat "$testcase" | sed -n ${arg_idx}p)
		[[ -z "$input_data" ]] && input_data+="$arg_name = $arg_data" || input_data+=", $arg_name = $arg_data"
		arg_data=$(echo "$arg_data" | sed 's@\[@\{@g;s@\]@\}@g;s/\*//g')
		[[ -z "$answer" ]] || ans_data=$(cat "$answer" | sed -n ${loop_idx}p | sed 's@\[@\{@g;s@\]@\}@g')
		((arg_idx++))
		declare_arguments+="	$arg${loop_idx} = $arg_data;
"

		[[ -z "$method_arguments" ]] && method_arguments+="${arg_name}${loop_idx}" || method_arguments+=", ${arg_name}${loop_idx}"
	done < <(echo "$full_args" | sed 's/,/\n/g')

	if [ "$ret_type" == "void" ]; then
		call_method+="
	cout << \"\\n[+] Input: ${input_data}\\n\";
	s.${method_name}($method_arguments);
	string delim1 = \"[+] Output: [\";
	for (auto &x: $arg_name) {
		cout << delim1 << '['; string delim2 = \"\";
		for (auto &y: x) {
			cout << delim2 << y; delim2 = \",\";
		}
		cout << \"]\"; delim1 = \",\";
	}
	cout << \"]\\n\";
"
		[[ -z "$answer" ]] || compare_answer+="	if (ans${loop_idx} != ${arg_name})
		cout << \"[ ] Test case ${loop_idx} : Wrong Answer\\n\";
	else
		cout << \"[+] Test case ${loop_idx} : Accepted\\n\";

"
	else
		[[ -z "$answer" ]] || declare_answer+="	$ret_type ans${loop_idx} = $ans_data;
"
		call_method+="
	cout << \"\\n[+] Input: ${input_data}\\n\";
	$ret_type result${loop_idx} = s.${method_name}($method_arguments);
	cout << \"[+] Output: \" << result${loop_idx} << endl;
"
		[[ -z "$answer" ]] || compare_answer+=" if (ans${loop_idx} != result${loop_idx})
		cout << \"[ ] Test case ${loop_idx} : Wrong Answer\\n\";
	else
		cout << \"[+] Test case ${loop_idx} : Accepted\\n\";
"
	fi

	cat <<EOF > ${test_src}
#include <bits/stdc++.h>
using namespace std;

#include "$solution"

int main() {
	ios_base::sync_with_stdio(false);
	cin.tie(0);
$declare_arguments
$declare_answer
	Solution s;
	$call_method
	$compare_answer
	return 0;
}
EOF
	((loop_idx++))
done

$CXX $CPPFLAGS "$test_src" -o "$test_bin" || { echo "[!] COMPILE ERROR"; exit 1; }
if [ "$execute" -eq 1 ]; then
	$test_bin
fi
[[ "$delete" -eq 1 ]] && rm "$test_src" "$test_bin"
