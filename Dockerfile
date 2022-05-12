ARG PROJECT_ID
ARG LOCATION
ARG _DOCKER_REPO

FROM ${LOCATION}-docker.pkg.dev/${PROJECT_ID}/${_DOCKER_REPO}/alltheplaces-builder AS builder

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

