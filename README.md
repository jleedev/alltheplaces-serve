Vector tile server for the [All The Places][1] data.

[1]: https://www.alltheplaces.xyz/

View the map: https://jleedev.github.io/alltheplaces-serve/

This has three moving parts:

1. Backend on cloud run
2. CDN on firebase hosting
3. Frontend on github pages
4. Scheduled artifact registry cleanup

The build process:

1. Fetches the latest tarball from All The Places
2. Removes those features lacking geometry or at null island etc.
3. Pipes to tippecanoe for clustering and tiling
4. Packages the mbtiles with a server and pushes to artifact registry and cloud run

This is all done on cloud build, but could easily be shifted elsewhere and pushed to artifact registry, which is all cloud run requires.

The firebase and gh-pages steps are trivial pushes without anything you'd call a build, although the firebase deploy is scheduled in order to clear the CDN cache.

Disclaimer: This readme is mostly written for myself.

Prerequisite checklist:

Once:

0. Fork this repository so as to be able to connect a build trigger
1. Enable the necessary APIs in GCP and firebase, create docker repo
2. Build the builder image (this build depends on the tippecanoe image, mainly because that is a CI image for testing, not optimized for deployment)
3. Put correct tileJson url in map style
4. Install and configure gcr-cleaner
5. Deploy to firebase hosting
6. Connect github repository to cloud build; create manual trigger
7. Schedule your trigger for "0 8 * * Tue" UTC.
8. Build the firebase builder: https://cloud.google.com/build/docs/deploying-builds/deploy-firebase (except use artifact registry instead of container registry)

Authorize cloud build to deploy to firebase

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role=roles/firebasehosting.admin 
```

As needed:

1. Push static content to github pages

Scheduled tasks:

1. Build and deploy new data server
2. Delete old versions of data server from artifact registry

Deploy to firebase:

```
>.firebaserc jq --arg PROJECT_ID "$(gcloud config get project)" \
  -n '.projects.default=$PROJECT_ID'
npx firebase-tools deploy --only hosting
```

Verify:

- Visit /cloudscheduler on cloud console. Find your cloud build scheduler and push RUN NOW. Scheduled job should turn green immediately.
- Hop over to /cloud-build. Build should turn green in 8-12 minutes.
- Hop over to /artifacts and find digests for your image. New one should appear.
- Hop over to /run and find revision of your service. Image url should be the latest digest.
- Go back to /cloudscheduler and push RUN NOW on gcrclean-alltheplaces. Scheduled job should turn green immediately.
- Go back to /artifacts and see all but latest digest are removed.

Long term:

Main costs to monitor are:

- Cloud storage bucket - extremely low, 0.1 GB-month
- Cloud run seconds - extremely low thanks to firebase hosting
- Cloud build minutes - about $0.10 per weekly build
- Firebase bandwidth - unknown as of yet
