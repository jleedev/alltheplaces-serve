#!/bin/bash

set -eux

[ -r .env ] && . .env

[ -v PROJECT_ID ] || (
  PROJECT_ID="$(gcloud config get-value project)"
  [ "$PROJECT_ID" != "" ]
)

gcloud() {
  command gcloud --project=$PROJECT_ID "$@"
}

# Asserts that the APIs are enabled
gcloud builds list
gcloud run services list

gcloud builds submit \
  --tag gcr.io/$PROJECT_ID/alltheplaces --timeout 30m

gcloud run deploy \
  --platform managed alltheplaces \
  --image gcr.io/$PROJECT_ID/alltheplaces \
  --memory 128Mi

gcloud container images list-tags \
  gcr.io/$PROJECT_ID/alltheplaces --format=json \
  | jq -rc '.[]|select(.tags==[]).digest' \
  | while read DIGEST
do
  gcloud container images delete \
    gcr.io/$PROJECT_ID/alltheplaces@$DIGEST
done

# vi: ts=2 sw=2 et

