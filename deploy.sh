#!/bin/bash

set -eux

PROJECT=$(gcloud config get-value project)
gcloud builds submit --tag gcr.io/$PROJECT/alltheplaces
gcloud run deploy --platform managed alltheplaces --image gcr.io/$PROJECT/alltheplaces --memory 1024Mi
