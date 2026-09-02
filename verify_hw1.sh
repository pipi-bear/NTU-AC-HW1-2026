#!/usr/bin/env bash

set -u
set -o pipefail

usage() {
    echo "Usage:"
    echo "  bash verify_hw1.sh <student_id> info"
    echo "  bash verify_hw1.sh <student_id> test"
}

if [[ $# -ne 2 ]]; then
    usage
    exit 1
fi

STUDENT_ID="$1"
MODE="$2"

INSTALL_SCRIPT="./install_bril.sh"
TESTS_DIR="./tests"

print_identity() {
    echo "============================================================"
    echo "ACD HW1 Verification"
    echo "============================================================"
    echo "Student ID        : $STUDENT_ID"
    echo "Timestamp         : $(date -Iseconds)"
    echo "Working directory : $(pwd)"
    echo
}

print_system_info() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "Operating system  : ${PRETTY_NAME:-unknown}"
    else
        echo "Operating system  : unknown"
    fi

    echo "Architecture      : $(uname -m)"
}

run_info() {
    print_identity
    print_system_info

    echo
    echo "---------------- install_bril.sh ----------------"

    if [[ ! -f "$INSTALL_SCRIPT" ]]; then
        echo "ERROR: install_bril.sh not found."
        exit 1
    fi

    echo
    echo "SHA256:"
    sha256sum "$INSTALL_SCRIPT"

    echo
    echo "Contents:"
    nl -ba "$INSTALL_SCRIPT"

    echo
    echo "---------------- End of Screenshot 1 ----------------"
}

run_test() {
    print_identity
    print_system_info

    local p0=0 p1=0 p2=0 p3=0

    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT

    echo
    echo "---------------- Problem 0: timeout 60 bash install_bril.sh ----------------"

    if [[ ! -f "$INSTALL_SCRIPT" ]]; then
        echo "ERROR: install_bril.sh not found."
    else
        start_ms=$(date +%s%3N)
        # --foreground keeps the script in the terminal's foreground process
        # group; without it, any tool that touches stdin gets stopped by
        # SIGTTIN when run interactively, and the install freezes until the
        # limit. The script output goes to a file to keep this report short;
        # it is shown only when the install fails.
        timeout --foreground 60 bash "$INSTALL_SCRIPT" > "$tmp_dir/install.log" 2>&1
        install_status=$?
        end_ms=$(date +%s%3N)
        elapsed=$(awk -v s="$start_ms" -v e="$end_ms" 'BEGIN { printf "%.1f", (e - s) / 1000 }')

        if [[ "$install_status" -eq 124 ]]; then
            echo "install_bril.sh exceeded the 60 second limit."
        elif [[ "$install_status" -ne 0 ]]; then
            echo "install_bril.sh failed with exit status $install_status after ${elapsed}s."
        else
            echo "install_bril.sh finished in ${elapsed}s (limit: 60s)."
            p0=1
        fi

        if [[ "$install_status" -ne 0 ]]; then
            echo
            echo "Last 20 lines of the script output:"
            tail -20 "$tmp_dir/install.log"
        fi
    fi
    echo "Problem 0 score: $p0 / 1"

    echo
    echo "---------------- Tool locations ----------------"

    for tool in bril2json brili bril2txt; do
        if path=$(command -v "$tool" 2>/dev/null); then
            echo "$tool : $path"
        else
            echo "$tool : NOT FOUND"
        fi
    done

    echo
    echo "---------------- Problem 1: bril2json < tests/rem.bril ----------------"

    if [[ ! -f "$TESTS_DIR/rem.bril" ]]; then
        echo "ERROR: $TESTS_DIR/rem.bril not found. Run this script from the repository root."
    elif output=$(bril2json < "$TESTS_DIR/rem.bril" 2>&1 > "$tmp_dir/rem.json"); then
        echo "Converted tests/rem.bril to JSON."
        p1=2
    else
        printf '%s\n' "$output"
        echo "bril2json failed."
    fi
    echo "Problem 1 score: $p1 / 2"

    echo
    echo "---------------- Problem 2: brili 9223372036854775783 6854775643 ----------------"

    if output=$(brili 9223372036854775783 6854775643 < "$tmp_dir/rem.json" 2>&1); then
        printf '%s\n' "$output" > "$tmp_dir/rem.tmp"
        echo "brili output: $output"
        p2=2
    else
        printf '%s\n' "$output"
        echo "brili failed."
    fi
    echo "Problem 2 score: $p2 / 2"

    echo
    echo "---------------- Problem 3: compare with tests/rem.out ----------------"

    if [[ ! -f "$TESTS_DIR/rem.out" ]]; then
        echo "ERROR: $TESTS_DIR/rem.out not found. Run this script from the repository root."
    elif diff "$tmp_dir/rem.tmp" "$TESTS_DIR/rem.out" 2>&1; then
        echo "brili output matches the expected output."
        p3=2
    else
        echo "brili output does not match the expected output."
    fi
    echo "Problem 3 score: $p3 / 2"

    local total=$((p0 + p1 + p2 + p3))

    echo
    echo "============================================================"
    echo "Score summary"
    echo "  Problem 0 (installation)       : $p0 / 1"
    echo "  Problem 1 (bril2json)          : $p1 / 2"
    echo "  Problem 2 (brili)              : $p2 / 2"
    echo "  Problem 3 (output comparison)  : $p3 / 2"
    echo "TOTAL SCORE: $total / 7"
    echo "============================================================"

    if [[ "$total" -ne 7 ]]; then
        exit 1
    fi
}

case "$MODE" in
    info)
        run_info
        ;;
    test)
        run_test
        ;;
    *)
        usage
        exit 1
        ;;
esac
