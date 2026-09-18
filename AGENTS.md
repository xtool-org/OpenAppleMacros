# OpenAppleMacros

This repo is an open source implementations of proprietary Apple SDK macros.

**In scope:** macros that are specific to Apple frameworks (e.g. SwiftUI, SwiftData) and are not in the open source https://swift.org toolchain distributions.

**Mostly out of scope:** macros that are already in the open source toolchains.

## Testing

Add fixtures to `IntegrationTests/<module>`. Then, invoke `./IntegrationTests/run.sh [dir|file]...` (preferably, run it unsandboxed) to compare Apple's actual expansion to our reimplementation. Invoke without an argument to perform all tests.

If test `IntegrationTests/Foo/Bar.swift` fails, expansions will be written to `IntegrationTests/Foo/Bar.swift.logs/{apple,custom,diff}.txt`

When writing tests, consider both valid & malformed input. Diagnostics should match Apple's.

## Internals

- Apple's macro implementations can be found at `$(xcode-select -p)/Platforms/*.platform/Developer/usr/lib/swift/host/plugins/*.dylib`.
- Standard Swift macros (usually available in OSS as well) can be found at `$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins`

The macros are referenced in various `swiftinterface`s. For example, SwiftUI declares

```swift
macro Preview(<snip>) = #externalMacro(module: "PreviewsMacros", type: "SwiftUIView")
```

referring to the `PreviewsMacros.SwiftUIView` macro in `libPreviewsMacros.dylib`.
