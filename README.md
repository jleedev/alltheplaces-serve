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

The firebase and gh-pages steps are trivial pushes without anything you'd call a build.

The cloud build is triggered weekly by a cron on my computer somewhere.

Prerequisite checklist:

Once:

1. Enable the necessary APIs in GCP and firebase, create docker repo
2. Build the builder image
3. Put correct tileJson url in map style
4. Install and configure gcr-cleaner
5. Deploy to firebase hosting
6. Connect github repository to cloud build; create manual trigger; specify value of `_DOCKER_REPO`; schedule your trigger

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

Visit /cloudscheduler on cloud console. Find your cloud build scheduler and push RUN NOW. Hop over to /cloud-build and your build should complete in about ten minutes.
