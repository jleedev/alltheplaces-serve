#!/bin/bash

[ -r .env ] && . .env

set -eu

PROJECT_ID=$(gcloud config get-value project)
[ -n $PROJECT_ID ] || (
  echo "Set project with gcloud config set project, or"
  echo "export CLOUDSDK_CORE_PROJECT=foo-bar-123 >> .env"
  exit 1
)

set -x

gcloud builds submit

[[ ${NO_CLEANUP+x} ]] && exit 1

gcloud artifacts docker images list \
    us-central1-docker.pkg.dev/$PROJECT_ID/my-docker-repo/alltheplaces \
    --format json --include-tags \
  | jq -r '.[]|select(.tags=="")|[.package,.version]|join("@")' \
  | while read IMAGE
do
  gcloud artifacts docker images delete $IMAGE
done

# vi: ts=2 sw=2 et

