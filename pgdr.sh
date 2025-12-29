
#!/bin/bash
# pgdr.sh — CLI password generator

length=16
lowercase_only=false
uppercase_only=false
with_nums=false
with_symbols=false
use_random=false 

while getopts "l:LUnShR" opt; do
    case $opt in
        l) length="$OPTARG" ;;
        L) lowercase_only=true ;;
        U) uppercase_only=true ;;
        n) with_nums=true ;;
        S) with_symbols=true ;;
        R) use_random=true ;; 
        h) 
            cat << EOF
passgen.sh 1.0 — Password generator from /dev/urandom or /dev/random

USAGE:
    $0 -l <length> [-L] [-U] [-n] [-S] [-R]

OPTIONS:
    -l <length>    Password length (REQUIRED)
    -L             Only lowercase letters a-z
    -U             Only uppercase letters A-Z  
    -n             Include numbers 0-9
    -S             Include symbols !@#$%^&*()_+-=
    -R             Use /dev/random (blocks on low entropy)
    -h             Show this help

EXAMPLES:
    $0 -l 16 -L                     # /dev/urandom + lowercase
    $0 -l 32 -L -U -n -S            # Full charset (/dev/urandom)
    $0 -l 16 -L -R                  # /dev/random + lowercase

NOTES:
    -R: Blocks if low entropy (safer but slower)
    -L + -U = both cases (a-zA-Z)
    Default: /dev/urandom (fast, production-ready)
EOF
            exit 0
            ;;
        \?) echo "Usage: $0 -l <length> [-L] [-U] [-n] [-S] [-R] [-h]" >&2; exit 1 ;;
    esac
done

if [ "$lowercase_only" = false ] && [ "$uppercase_only" = false ] && [ "$with_nums" = false ] && [ "$with_symbols" = false ]; then
    echo "Error: specify at least one character type: -L/-U/-n/-S" >&2
    echo "Usage: $0 -l <length> [-L] [-U] [-n] [-S] [-R]" >&2
    exit 1
fi

charset=""
if [ "$lowercase_only" = true ] && [ "$uppercase_only" = false ]; then
    charset="a-z"
elif [ "$uppercase_only" = true ] && [ "$lowercase_only" = false ]; then
    charset="A-Z"
elif [ "$lowercase_only" = true ] && [ "$uppercase_only" = true ]; then
    charset="a-zA-Z"
fi

if [ "$with_nums" = true ]; then
    charset="${charset}0-9"
fi

if [ "$with_symbols" = true ]; then
    charset="${charset}!@#$%^&*()_+-="
fi

if [ "$use_random" = true ]; then
    entropy_source="/dev/random"
    echo "Using /dev/random (may block on low entropy)" >&2
else
    entropy_source="/dev/urandom"
fi

timeout=10  # seconds
if timeout "$timeout" tr -dc "$charset" < "$entropy_source" | head -c "$length" | tr -d '\0' | grep -q .; then
    tr -dc "$charset" < "$entropy_source" | head -c "$length" | tr -d '\0'; echo
else
    echo "Error: /dev/random blocked (low entropy). Use -R only for small passwords or wait." >&2
    echo "Tip: Use default /dev/urandom for production (no blocking)." >&2
    exit 1
fi

