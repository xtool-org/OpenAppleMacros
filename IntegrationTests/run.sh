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
    swiftc -color-diagnostics "$1" -driver-print-jobs | head -1
}

function expand() {
    frontend_command="$(get_frontend_command "$1")"
    custom_command="$(echo "$frontend_command" | sed "s|$apple_plugin_server_path|$custom_plugin_server_path|g")"

    frontend_ast="$(eval "$frontend_command -print-ast" 2>&1)"
    frontend_expansion="$(eval "$frontend_command -dump-macro-expansions" 2>&1)"
    frontend_output="$frontend_ast"$'\n'"++++++++++++"$'\n'"$frontend_expansion"

    custom_ast="$(eval "$custom_command -print-ast" 2>&1)"
    custom_expansion="$(eval "$custom_command -dump-macro-expansions" 2>&1)"
    custom_output="$custom_ast"$'\n'"++++++++++++"$'\n'"$custom_expansion"

    rm -rf "$1.logs"
    if [[ "$frontend_output" == "$custom_output" ]]; then
        echo "✅ $1: pass"
        return 0
    else
        mkdir -p "$1.logs/"
        echo "$frontend_output" > "$1.logs/apple.txt"
        echo "$custom_output" > "$1.logs/custom.txt"
        diff "$1".logs/{apple,custom}.txt > "$1.logs/diff.txt" || true
        echo "❌ $1: fail: wrote to $1.logs/"
        return 1
    fi
}

function expand_many() {
    did_fail=0
    for file in $(find "$1" -name "*.swift"); do
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
