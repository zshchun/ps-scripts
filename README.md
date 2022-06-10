# CLI Scripts for Problem Sovling 

## Requirements
bash, awk, xxd, [curl](https://github.com/curl/curl), [jq](https://github.com/stedolan/jq), [clang](https://github.com/llvm/llvm-project), [openssl](https://github.com/openssl/openssl), [pup](https://github.com/ericchiang/pup)

## cf-solved.sh
Check solved problems for recent [codeforces](https://codeforces.com/) contests.

### Usage
```
# Get Div.2 contests from latest 3 codeforces page
$ cf-solved.sh 3 2

# Check solved problem A to E
$ CF_LEVEL=A-C cf-solved.sh
...
1473  A B C  Educational Codeforces Round 102 (Rated for Div. 2)
1471  A B C  Codeforces Round #694 (Div. 2)
1469      C  Educational Codeforces Round 101 (Rated for Div. 2)
1467  A B C  Codeforces Round #695 (Div. 2)
[*] Solved 2 contests
```

### Limiation
It does not ordered by date. (by contest\_id) \
It does not guarantee thea you solved a problem. It checks if file exists.

## cf-get-solutions.sh
View solutions from [codeforces](https://codeforces.com/) contests.

### Usage
```
$ cf-get-solutions.sh 1469 a
[+] 1469 A
[+] Page 1
    #           When                 Who                     Problem                 Lang      Verdict   Time  Memory
...
View this submission? [Yn] 

# Set editor
$ CF_PAGER=emacs cf-get-solutions.sh 

# make directory hierarchy
/src/codeforces/1469/a $ cf-get-solutions.sh 
```

## cf-editorial.sh
Print editorial blog url of contest

## lc-compile.sh
Compile and execute [leetcode](https://leetcode.com/) solutions on local machine.

### Usage
```
$ lc-compile.sh -x 9.palindrome-number.cpp 9.palindrome-number.tests.dat 9.palindrome-number.ans 
[+] Compile /src/9.palindrome-number.cpp with /tmp/tmp.vyAw4jzimj.cpp

[+] Input: x = 121
[+] Output: 1

[+] Input: x = -121
[+] Output: 0

[+] Input: x = 10
[+] Output: 0

[+] Test case 1 : Accepted
[+] Test case 2 : Accepted
[+] Test case 3 : Accepted
```

### Limiation
This script can not parse custom data structure. \
eg) struct ListNode of "2. Add Two Numbers"

Supported language : C++ (clang++)

# License
MIT
