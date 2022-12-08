ARG PROJECT_ID
FROM us-central1-docker.pkg.dev/$PROJECT_ID/my-docker-repo/tippecanoe AS tippecanoe

FROM debian:stable-slim AS builder

COPY --from=tippecanoe /usr/local/bin/* /usr/local/bin/

RUN apt-get update && \
        apt-get -y --no-install-recommends install python3-requests && \
        rm -rf /var/lib/apt/lists/*

