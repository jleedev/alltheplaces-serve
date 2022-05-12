#!/bin/bash

# Run this script once to install a cloud scheduler job to remove old versions
# of the data server.

# Describe .env here
#
# export CLOUDSDK_CORE_PROJECT=all-the-places-338115
# export CLOUDSDK_ARTIFACTS_LOCATION=us-central1
# export CLOUDSDK_ARTIFACTS_REPOSITORY=my-docker-repo
# export CLOUDSDK_RUN_REGION=us-central1
# export CLOUDSDK_RUN_PLATFORM=managed

[ -r .env ] && source .env

set -eu

die() {
  echo >&2 "$@"
  exit 1
}

PROJECT_ID=$(gcloud config get project)
[[ -n ${PROJECT_ID} ]] || die "Need CLOUDSDK_CORE_PROJECT="

set -x

gcloud services enable cloudscheduler.googleapis.com run.googleapis.com
gcloud iam service-accounts create gcr-cleaner
gcloud run deploy gcr-cleaner \
  --no-allow-unauthenticated \
  --service-account gcr-cleaner@${PROJECT_ID}.iam.gserviceaccount.com \
  --image us-docker.pkg.dev/gcr-cleaner/gcr-cleaner/gcr-cleaner \
  --timeout 60s

gcloud artifacts repositories add-iam-policy-binding my-docker-repo \
  --member serviceAccount:gcr-cleaner@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/artifactregistry.repoAdmin

gcloud iam service-accounts create gcr-cleaner-invoker
gcloud run services add-iam-policy-binding gcr-cleaner \
  --member serviceAccount:gcr-cleaner-invoker@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/run.invoker

SERVICE_URL=$(gcloud run services describe gcr-cleaner --format 'value(status.url)')
REPO=$(gcloud config get artifacts/location)-docker.pkg.dev/${PROJECT_ID}/$(gcloud config get artifacts/repository)/alltheplaces

gcloud scheduler jobs create http "gcrclean-alltheplaces" \
  --description "Cleanup ${REPO}" \
  --uri "${SERVICE_URL}/http" \
  --message-body $(jq --arg REPO $REPO -cn '.repos=[$REPO]') \
  --oidc-service-account-email "gcr-cleaner-invoker@${PROJECT_ID}.iam.gserviceaccount.com" \
  --schedule "0 */12 * * *"

