#!/bin/bash

set -euo pipefail

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
    echo "Usage: $0 [dir|file.swift]..."
    echo "  Leave blank to run all tests in IntegrationTests"
    echo "  Set OPEN_APPLE_MACROS_TEST_JOBS to override the physical CPU count"
    echo "  Set OPEN_APPLE_MACROS_TEST_TARGET to test a deployment target"
    exit 1
fi

export SWIFT_DETERMINISTIC_HASHING=1

apple_plugin_server_path="$(xcode-select -p)/Platforms/MacOSX.platform/Developer/usr/bin/swift-plugin-server"
custom_plugin_server_path="$PWD/.build/debug/OpenAppleMacrosServer"

function get_frontend_command() {
    if [[ -n ${OPEN_APPLE_MACROS_TEST_TARGET:-} ]]; then
        swiftc -target "$OPEN_APPLE_MACROS_TEST_TARGET" -color-diagnostics "$1" -driver-print-jobs | sed -n '1p'
    else
        swiftc -color-diagnostics "$1" -driver-print-jobs | sed -n '1p'
    fi
}

function expand() {
    local frontend_command custom_command
    local frontend_ast frontend_expansion custom_ast custom_expansion
    local frontend_ast_status=0 frontend_expansion_status=0
    local custom_ast_status=0 custom_expansion_status=0
    local frontend_output custom_output

    frontend_command="$(get_frontend_command "$1")"
    custom_command="$(echo "$frontend_command" | sed "s|$apple_plugin_server_path|$custom_plugin_server_path|g")"

    frontend_ast="$(eval "$frontend_command -print-ast" 2>&1)" || frontend_ast_status=$?
    frontend_expansion="$(eval "$frontend_command -dump-macro-expansions" 2>&1)" || frontend_expansion_status=$?
    frontend_output="AST exit: $frontend_ast_status"$'\n'"$frontend_ast"$'\n'"++++++++++++"$'\n'"Expansion exit: $frontend_expansion_status"$'\n'"$frontend_expansion"

    custom_ast="$(eval "$custom_command -print-ast" 2>&1)" || custom_ast_status=$?
    custom_expansion="$(eval "$custom_command -dump-macro-expansions" 2>&1)" || custom_expansion_status=$?
    custom_output="AST exit: $custom_ast_status"$'\n'"$custom_ast"$'\n'"++++++++++++"$'\n'"Expansion exit: $custom_expansion_status"$'\n'"$custom_expansion"

    rm -rf "$1.logs"
    # Apple serializes some objects in varying dictionary key order,
    # including with SWIFT_DETERMINISTIC_HASHING set. Sort JSON keys.
    local normalized_frontend normalized_custom
    normalized_frontend="$(printf '%s' "$frontend_output" | python3 IntegrationTests/normalize.py)"
    normalized_custom="$(printf '%s' "$custom_output" | python3 IntegrationTests/normalize.py)"
    if [[ "$normalized_frontend" == "$normalized_custom" ]]; then
        echo "✅ $1: pass"
        return 0
    else
        mkdir -p "$1.logs/"
        printf '%s\n' "$frontend_output" > "$1.logs/apple.txt"
        printf '%s\n' "$custom_output" > "$1.logs/custom.txt"
        diff "$1".logs/{apple,custom}.txt > "$1.logs/diff.txt" || true
        echo "❌ $1: fail: wrote to $1.logs/"
        return 1
    fi
}

if [[ ${1:-} == "--worker" ]]; then
    expand "$2"
    exit $?
fi

if [[ "$#" == 0 ]]; then
    set -- IntegrationTests
fi

for path in "$@"; do
    if [[ ! -e "$path" ]]; then
        echo "No such test path: $path" >&2
        exit 2
    fi
done

if [[ -n ${OPEN_APPLE_MACROS_TEST_JOBS:-} ]]; then
    parallel_jobs=$OPEN_APPLE_MACROS_TEST_JOBS
else
    parallel_jobs=$(sysctl -n hw.physicalcpu 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
fi
if [[ ! $parallel_jobs =~ ^[1-9][0-9]*$ ]]; then
    echo "OPEN_APPLE_MACROS_TEST_JOBS must be a positive integer" >&2
    exit 2
fi

files=()
while IFS= read -r -d '' file; do
    duplicate=0
    for existing in "${files[@]-}"; do
        if [[ "$existing" == "$file" ]]; then
            duplicate=1
            break
        fi
    done
    if [[ "$duplicate" == 0 ]]; then
        files+=("$file")
    fi
done < <(find "$@" -type f -name '*.swift' -print0)

if [[ ${#files[@]} == 0 ]]; then
    echo "No Swift test files found" >&2
    exit 2
fi

swiftc -print-target-info | jq -r .compilerVersion
swift build --product OpenAppleMacrosServer

test_label=test
if [[ ${#files[@]} != 1 ]]; then
    test_label=tests
fi
echo "Running ${#files[@]} $test_label with up to $parallel_jobs workers"
if printf '%s\0' "${files[@]}" | xargs -0 -n 1 -P "$parallel_jobs" "$0" --worker; then
    exit 0
else
    exit 1
fi
