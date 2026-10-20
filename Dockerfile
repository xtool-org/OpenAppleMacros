FROM swift:6.4.1

ARG SMOKE

RUN [ "$SMOKE" = 1 ] || swift sdk install \
    https://download.swift.org/swift-6.4.1-release/static-sdk/swift-6.4.1-RELEASE/swift-6.4.1-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz \
    --checksum cef5592d7430ed3c5ae1ddda479849c6f5252bd94a5723db1559f984caf38a7c

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        make \
    && rm -rf /var/lib/apt/lists/*

VOLUME ["/src"]

WORKDIR /src

CMD ["/bin/bash"]
