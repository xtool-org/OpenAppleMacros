FROM swift:6.1

ARG SMOKE

RUN [ "$SMOKE" = 1 ] || swift sdk install \
    https://download.swift.org/swift-6.1.1-release/static-sdk/swift-6.1.1-RELEASE/swift-6.1.1-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
    --checksum 8a69753e181e40c202465f03bcafcc898070a86817ca0f39fc808f76638e90c2

RUN [ "$SMOKE" = 1 ] && llvm="" || llvm="llvm-18"; \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        make \
        $llvm \
    && rm -rf /var/lib/apt/lists/*

ENV STRIP=llvm-strip-18

ADD . /src
WORKDIR /src

RUN swift package resolve
