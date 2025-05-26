all: macros server

WASM_OUT := .build/wasm32-unknown-wasi/release

ALL_MACROS := SwiftUIMacros

macros: $(foreach macro, $(ALL_MACROS), build-$(macro))

build-%:
	swift build --product $* --swift-sdk wasm32-unknown-wasi -c release
	llvm-strip $(WASM_OUT)/$*.wasm
	wasm-opt -Os $(WASM_OUT)/$*.wasm -o $(WASM_OUT)/$*.wasm

server:
	swift build --product wasm-plugin-server --swift-sdk aarch64-swift-linux-musl -c release -Xswiftc -Osize
	llvm-strip .build/aarch64-swift-linux-musl/release/wasm-plugin-server

# Usage:
#
# Create `wasm-plugins` directory, `mv %.wasm wasm-plugins/%.so`. Then,
#
# swift build --swift-sdk arm64-apple-ios \
#   -Xswiftc -external-plugin-path
#   -Xswiftc wasm-plugins#wasm-plugin-server
