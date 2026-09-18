# OpenAppleMacros

This repo is an open source implementations of proprietary Apple SDK macros.

**In scope:** macros that are specific to Apple frameworks (e.g. SwiftUI, SwiftData) and are not in the open source https://swift.org toolchain distributions.

**Out of scope:** macros that are already in the open source toolchains.

## Testing

Add fixtures to `IntegrationTests/<module>`. Then, invoke `./IntegrationTests/run.sh [dir|file]` (do it unsandboxed) to compare Apple's actual expansion to our reimplementation. Invoke without an argument to perform all tests.

If test `IntegrationTests/Foo/Bar.swift` fails, expansions will be written to `IntegrationTests/Foo/Bar.swift.logs/{apple,custom,diff}.txt`

When writing tests, consider both valid & malformed input. Diagnostics should match Apple's.
