# OpenAppleMacros

This repo is an open source implementations of proprietary Apple SDK macros.

**In scope:** macros that are specific to Apple frameworks (e.g. SwiftUI, SwiftData) and are not in the open source https://swift.org toolchain distributions.

**Mostly out of scope:** macros that are already in the open source toolchains.

## Testing

Add fixtures to `IntegrationTests/<module>`. Then, invoke `./IntegrationTests/run.sh [dir|file]...` (preferably, run it unsandboxed) to compare Apple's actual expansion to our reimplementation. Invoke without an argument to perform all tests.

If test `IntegrationTests/Foo/Bar.swift` fails, expansions will be written to `IntegrationTests/Foo/Bar.swift.logs/{apple,custom,diff}.txt`

When writing tests, consider (and this is non-exhaustive)

- Simple cases
- More complex cases
- Malformed input: diagnostics should match Apple's
- Edge cases for all of the above. Type inference, optionals, visibility, struct/enum/class/actor, nested types, fully qualified spellings, and any other relevant edge cases.

## Adding new macros

Make sure to read the `swiftinterface` that uses the macro, as well as the Apple developer documentation.

Apple developer docs: append `.md` to developer documentation links to get a machine-readable version. For example: <https://developer.apple.com/documentation/swiftui.md>, <https://developer.apple.com/documentation/swiftui/state.md>.

## Internals

- Apple's macro implementations can be found at `$(xcode-select -p)/Platforms/*.platform/Developer/usr/lib/swift/host/plugins/*.dylib`.
- Standard Swift macros (usually available in OSS as well) can be found at `$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins`

The macros are referenced in various `swiftinterface`s across the SDK.

For example, SwiftUI is at `$(xcrun -show-sdk-path -sdk macosx)/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/arm64e-apple-macos.swiftinterface` (+ `SwiftUICore.framework`). It declares:

```swift
macro Preview(<snip>) = #externalMacro(module: "PreviewsMacros", type: "SwiftUIView")
```

referring to the `PreviewsMacros.SwiftUIView` macro in `libPreviewsMacros.dylib`.

If the environment has access to reverse-engineering tools (like Hopper MCP), use those to be thorough.
