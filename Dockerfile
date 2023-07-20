ARG BUILDER_IMAGE
FROM ${BUILDER_IMAGE} AS builder

WORKDIR /build/
COPY update.py /build/
RUN >output.geojsons python3 update.py
RUN cat run_id.txt
RUN tippecanoe \
	-o output.mbtiles \
	--named-layer '{"file":"output.geojsons","layer":"alltheplaces"}' \
	--cluster-distance=25 \
	--drop-rate=1 \
	--maximum-zoom=13 \
	--cluster-maxzoom=g \
	--attribution="$(cat run_id.txt)"

FROM consbio/mbtileserver
COPY --from=builder /build/output.mbtiles /tilesets/

