FROM swift:6.3.3

ARG SMOKE

RUN [ "$SMOKE" = 1 ] || swift sdk install \
    https://download.swift.org/swift-6.3.3-release/static-sdk/swift-6.3.3-RELEASE/swift-6.3.3-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz \
    --checksum 87c3eaf908e67c0e13a84367119e12273cec1d2cd3d81f7d74bb36722d6b607b

RUN [ "$SMOKE" = 1 ] && llvm="" || llvm="llvm-18"; \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        make \
        $llvm \
    && rm -rf /var/lib/apt/lists/*

ENV STRIP=llvm-strip-18

VOLUME ["/src"]

WORKDIR /src

ENTRYPOINT ["/bin/bash", "-c"]
