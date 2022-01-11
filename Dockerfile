FROM gcr.io/asdf-f6040/tippecanoe AS tippecanoe

FROM debian:stable-slim AS builder

COPY --from=tippecanoe /usr/local/bin/* /usr/local/bin/

RUN apt-get update && \
	apt-get -y --no-install-recommends install \
		python3-bs4 python3-requests && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /build/
COPY update.py /build/
RUN >output.geojsons python3 update.py
RUN <output.geojsons tippecanoe -o output.mbtiles \
	-aC -r1 -z10 -A "$(cat run_id.txt)"

FROM consbio/mbtileserver
COPY --from=builder /build/output.mbtiles /tilesets/

