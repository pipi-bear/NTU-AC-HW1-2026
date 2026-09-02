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

    echo
    echo "---------------- Test 0: timeout 10 bash install_bril.sh ----------------"

    if [[ ! -f "$INSTALL_SCRIPT" ]]; then
        echo "ERROR: install_bril.sh not found."
        echo
        echo "RESULT: FAIL"
        exit 1
    fi

    start_ms=$(date +%s%3N)
    timeout 10 bash "$INSTALL_SCRIPT"
    install_status=$?
    end_ms=$(date +%s%3N)
    elapsed=$(awk -v s="$start_ms" -v e="$end_ms" 'BEGIN { printf "%.1f", (e - s) / 1000 }')

    echo
    if [[ "$install_status" -eq 124 ]]; then
        echo "install_bril.sh exceeded the 10 second limit."
        echo "Test 0 result: FAIL"
        test0_pass=0
    elif [[ "$install_status" -ne 0 ]]; then
        echo "install_bril.sh failed with exit status $install_status after ${elapsed}s."
        echo "Test 0 result: FAIL"
        test0_pass=0
    else
        echo "install_bril.sh finished in ${elapsed}s (limit: 10s)."
        echo "Test 0 result: PASS"
        test0_pass=1
    fi

    echo
    echo "---------------- Tool locations ----------------"

    local missing=0

    for tool in bril2json brili bril2txt; do
        if path=$(command -v "$tool" 2>/dev/null); then
            echo "$tool : $path"
        else
            echo "$tool : NOT FOUND"
            missing=1
        fi
    done

    if [[ "$missing" -ne 0 ]]; then
        echo
        echo "RESULT: FAIL"
        echo "One or more required tools could not be found."
        exit 1
    fi

    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT

    cat > "$tmp_dir/add.bril" <<'EOF'
@main {
  v0: int = const 4;
  v1: int = const 2;
  sum: int = add v0 v1;
  print sum;
}
EOF

    echo
    echo "---------------- Test program ----------------"
    cat "$tmp_dir/add.bril"

    echo
    echo "---------------- Test 1: bril2json | brili ----------------"

    brili_output=$(
        {
            bril2json < "$tmp_dir/add.bril" | brili
        } 2>&1
    )
    brili_status=$?

    printf '%s\n' "$brili_output"

    if [[ "$brili_status" -eq 0 && "$brili_output" == "6" ]]; then
        echo "Test 1 result: PASS"
        test1_pass=1
    else
        echo "Test 1 result: FAIL"
        test1_pass=0
    fi

    echo
    echo "---------------- Test 2: bril2json | bril2txt ----------------"

    roundtrip_output=$(
        {
            bril2json < "$tmp_dir/add.bril" | bril2txt
        } 2>&1
    )
    roundtrip_status=$?

    printf '%s\n' "$roundtrip_output"

    if [[ "$roundtrip_status" -eq 0 ]]; then
        echo "Test 2 result: PASS"
        test2_pass=1
    else
        echo "Test 2 result: FAIL"
        test2_pass=0
    fi

    echo
    echo "============================================================"

    if [[ "$test0_pass" -eq 1 && "$test1_pass" -eq 1 && "$test2_pass" -eq 1 ]]; then
        echo "FINAL RESULT: PASS"
    else
        echo "FINAL RESULT: FAIL"
        exit 1
    fi

    echo "============================================================"
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
