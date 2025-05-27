# OpenAppleMacros

Open source implementations of Apple SDK macros.

**Note:** This package is currently WIP. See [xtool#101](https://github.com/xtool-org/xtool/pull/101)

## Usage

This package is used by [xtool](https://github.com/xtool-org/xtool): [OpenAppleMacrosServer](/Sources/OpenAppleMacrosServer) is installed into the Darwin SDK that we build.

Specifically, `OpenAppleMacrosServer` is a drop-in replacement for `Xcode.app/Contents/Developer/Platforms/*.platform/Developer/usr/bin/swift-plugin-server`.

The only other caveat is that we have to replace the `lib<FOO>Macros.dylib` files (in `*.platform/Developer/usr/lib/swift/host/plugins/`) with empty `lib<FOO>Macros.so` files, so that swiftc registers them as macro modules. The files stay blank because we don't *actually* split the macros up into shared libraries. Instead we merge all of the macros into the `OpenAppleMacrosServer` executable, and statically link it, for maximum portability.

## Development

The easiest way to build the server yourself is by running `make docker`.

You can test out the server by replacing `darwin.artifactbundle/OpenAppleMacrosServer` with the built `output/OpenAppleMacrosServer-$(arch)`.
