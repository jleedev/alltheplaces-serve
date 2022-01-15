#!/bin/bash

[ -r .env ] && . .env

set -eu

[ -n "$(gcloud config get-value project)" ] || (
  echo "Set project with gcloud config set project, or"
  echo "export CLOUDSDK_CORE_PROJECT=foo-bar-123 >> .env"
  exit 1
)

set -x

gcloud builds submit

gcloud artifacts docker images list \
    us-central1-docker.pkg.dev/$PROJECT_ID/my-docker-repo/alltheplaces \
    --format json --include-tags \
  | jq '.[]|select(.tags=="")|[.package,.version]|join("@")' \
  | while read IMAGE
do
  gcloud artifacts docker images delete $IMAGE
done

# vi: ts=2 sw=2 et

