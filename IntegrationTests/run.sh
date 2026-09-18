#!/bin/bash

set -euo pipefail

if [[ $# -gt 1 || ${1:-} == "-h" || ${1:-} == "--help" ]]; then
    echo "Usage: $0 [dir|file.swift]"
    echo "  Leave blank to run all tests in IntegrationTests"
    exit 1
fi

swiftc -print-target-info | jq -r .compilerVersion

swift build --product OpenAppleMacrosServer

apple_plugin_server_path="$(xcode-select -p)/Platforms/MacOSX.platform/Developer/usr/bin/swift-plugin-server"
custom_plugin_server_path="$PWD/.build/debug/OpenAppleMacrosServer"

function get_frontend_command() {
    swiftc "$1" -driver-print-jobs | head -1
}

function expand() {
    frontend_command="$(get_frontend_command "$1")"
    custom_command="$(echo "$frontend_command" | sed "s|$apple_plugin_server_path|$custom_plugin_server_path|g")"

    frontend_ast="$(eval "$frontend_command -print-ast" 2>&1)"
    custom_ast="$(eval "$custom_command -print-ast" 2>&1)"
    frontend_expansion="$(eval "$frontend_command -dump-macro-expansions" 2>&1)"
    custom_expansion="$(eval "$custom_command -dump-macro-expansions" 2>&1)"

    if [[ "$frontend_ast" == "$custom_ast" ]]; then
        echo "=== AST: match ==="
    else
        echo "=== AST: Apple ==="
        echo "$frontend_ast"
        echo "=== AST: Custom ==="
        echo "$custom_ast"
        echo "=== AST: Diff ==="
        diff <(echo "$frontend_ast") <(echo "$custom_ast") || true
    fi

    if [[ "$frontend_expansion" == "$custom_expansion" ]]; then
        echo "=== EXPANSION: match ==="
    else
        echo "=== EXPANSION: Apple ==="
        echo "$frontend_expansion"
        echo "=== EXPANSION: Custom ==="
        echo "$custom_expansion"
        echo "=== EXPANSION: Diff ==="
        diff <(echo "$frontend_expansion") <(echo "$custom_expansion") || true
    fi

    if [[ "$frontend_expansion" == "$custom_expansion" && "$frontend_ast" == "$custom_ast" ]]; then
        echo "=== Test passed: $1 ==="
        return 0
    else
        echo "=== Test failed: $1 ==="
        return 1
    fi
}

function expand_many() {
    did_fail=0
    for file in $(find "$1" -name "*.swift"); do
        echo "===== Testing $file ====="
        if ! expand "$file"; then
            did_fail=1
        fi
    done
    return $did_fail
}

if [[ "$#" == 0 ]]; then
    expand_many IntegrationTests
elif [[ -d "$1" ]]; then
    expand_many "$1"
else
    expand "$1"
fi
