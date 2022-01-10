#!/bin/bash

set -eux

PROJECT=$(gcloud config get-value project)
gcloud builds submit --tag gcr.io/$PROJECT/alltheplaces
gcloud run deploy --platform managed alltheplaces --image gcr.io/$PROJECT/alltheplaces --memory 1024Mi

gcloud container images list-tags gcr.io/$PROJECT/alltheplaces --format=json | jq -rc '.[]|select(.tags==[]).digest' | while read DIGEST
do
  gcloud container images delete gcr.io/$PROJECT/alltheplaces@$DIGEST
done

# vi: ts=2 sw=2 et

