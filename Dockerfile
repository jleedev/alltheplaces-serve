FROM debian:bullseye-slim AS builder

RUN apt-get update && \
	apt-get -y --no-install-recommends install \
		gdal-bin python3-bs4 python3-requests && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /build/
COPY update.py /build/
RUN python3 update.py > output.geojson
RUN ogr2ogr output.gpkg output.geojson

FROM gospatial/tegola
WORKDIR /data/
COPY --from=builder /build/output.gpkg /data/
COPY config.toml /data/

ENV PORT 8080
ENTRYPOINT []
CMD /opt/tegola serve --config /data/config.toml --port ":$PORT"

