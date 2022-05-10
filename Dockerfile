ARG PROJECT_ID
FROM us-central1-docker.pkg.dev/$PROJECT_ID/my-docker-repo/tippecanoe AS tippecanoe

FROM debian:stable-slim AS builder

COPY --from=tippecanoe /usr/local/bin/* /usr/local/bin/

RUN apt-get update && \
	apt-get -y --no-install-recommends install \
		python3-bs4 python3-requests && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /build/
COPY update.py /build/
RUN >output.geojsons python3 update.py
RUN cat run_id.txt
RUN tippecanoe \
	-o output.mbtiles \
	--layer output \
	--cluster-densest-as-needed \
	--drop-rate=1 \
	--maximum-zoom=11 \
	--maximum-tile-features=20000 \
	--attribution="$(cat run_id.txt)" \
	--read-parallel output.geojsons

FROM consbio/mbtileserver
COPY --from=builder /build/output.mbtiles /tilesets/

