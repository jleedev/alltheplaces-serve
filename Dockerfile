ARG BUILDER_IMAGE
FROM ${BUILDER_IMAGE} AS builder

WORKDIR /build/
COPY update.py /build/
RUN >output.geojsons python3 update.py
RUN cat run_id.txt
RUN tippecanoe \
	-o output.mbtiles \
	--layer alltheplaces \
	--cluster-densest-as-needed \
	--drop-rate=1 \
	--maximum-zoom=11 \
	--maximum-tile-features=20000 \
	--attribution="$(cat run_id.txt)" \
	--read-parallel output.geojsons

FROM consbio/mbtileserver
COPY --from=builder /build/output.mbtiles /tilesets/

