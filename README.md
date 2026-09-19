# OpenAppleMacros

Open source implementations of Apple SDK macros.

**Note:** This package is currently WIP. See [xtool#101](https://github.com/xtool-org/xtool/pull/101)

## Versioning policy

We always track one specific version of Xcode at a time. OAM macros aim to be byte-for-byte compatible with Apple's macros in the tracked version (although we're not entirely there yet).

Currently tracking: **Xcode 27.0.0 (27A266a)**.

## Usage

This package is used by [xtool](https://github.com/xtool-org/xtool): [OpenAppleMacrosServer](/Sources/OpenAppleMacrosServer) is installed into the Darwin SDK that we build.

Specifically, `OpenAppleMacrosServer` is a drop-in replacement for `Xcode.app/Contents/Developer/Platforms/*.platform/Developer/usr/bin/swift-plugin-server`.

The only other caveat is that we have to replace the `lib<FOO>Macros.dylib` files (in `*.platform/Developer/usr/lib/swift/host/plugins/`) with empty `lib<FOO>Macros.so` files, so that swiftc registers them as macro modules. The files stay blank because we don't *actually* split the macros up into shared libraries. Instead we merge all of the macros into the `OpenAppleMacrosServer` executable, and statically link it, for maximum portability.

## Development

The easiest way to build the server yourself is by running `make docker`.

You can test out the server by replacing `darwin.artifactbundle/OpenAppleMacrosServer` with the built `output/OpenAppleMacrosServer-$(arch)`.

## Integration tests

There's a test suite of source snippets in `./IntegrationTests`. Invoking `./IntegrationTests/run.sh` will expand each snippet using 1. Apple's implementation and 2. our implementation, and check whether they're identical.

## Status

Implementation is partially complete. PRs are welcome; AI agents are quite good at adding coverage.

Legend:

- ✅ = fully supported
- 🌗 = partially supported
- ❌ = not yet supported

### ❌ AppIntents

AppIntents also emits extra metadata via `appintentsmetadataprocessor`, so implementing support will require
more than just the macros.

| Macro | Status | Notes |
| - | - | - |
| `@AppEntity` | ❌ | |
| `@AppEnum` | ❌ | |
| `@AppIntent` | ❌ | |
| `@AssistantEntity` | ❌ | |
| `@AssistantEnum` | ❌ | |
| `@AssistantIntent` | ❌ | |
| `@ComputedProperty` | ❌ | |
| `@DeferredProperty` | ❌ | |
| `@UnionValue` | ❌ | |

### ❌ FoundationModels

| Macro | Status | Notes |
| - | - | - |
| `@Generable` | ❌ | |
| `@Guide` | ❌ | |
| `@SessionPropertyEntry` | ❌ | |

### 🌗 Previews

Applies to `AppKit`, `SwiftUI`, `UIKit`, `WidgetKit`

| Macro | Status | Notes |
| - | - | - |
| `@Preview` | 🌗 | Expands to empty output |
| `@Previewable` | 🌗 | Expands to empty output |

### ❌ StateReporting

| Macro | Status | Notes |
| - | - | - |
| `@ReportableMetadata` | ❌ | |
| `@ReportableMetadataIgnored` | ❌ | |
| `@ReportableMetadataKey` | ❌ | |

### ❌ SwiftData

| Macro | Status | Notes |
| - | - | - |
| `@Attribute` | ❌ | |
| `@Index` | ❌ | |
| `@Model` | ❌ | |
| `@ModelActor` | ❌ | |
| `@Query` | ❌ | |
| `@Relationship` | ❌ | |
| `@Transient` | ❌ | |
| `@Unique` | ❌ | |

### ✅ SwiftUI

| Macro | Status | Notes |
| - | - | - |
| `@Animatable` | ✅ | |
| `@AnimatableIgnored` | ✅ | |
| `@Entry` | ✅ | |
| `@State` | ✅ | |

### ❌ TipKit

| Macro | Status | Notes |
| - | - | - |
| `@Parameter` | ❌ | |
| `@Rule` | ❌ | |
