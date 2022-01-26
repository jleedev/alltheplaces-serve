Vector tile server for the [All The Places][1] data.

[1]: https://www.alltheplaces.xyz/

View the map: https://jleedev.github.io/alltheplaces-serve/

This has three moving parts:

1. Backend on cloud run
2. CDN on firebase hosting
3. Frontend on github pages

The build process:

1. Fetches the latest tarball from All The Places
2. Removes those features lacking geometry or at null island etc.
3. Pipes to tippecanoe for clustering and tiling
4. Packages the mbtiles with a server and pushes to artifact registry and cloud run

This is all done on cloud build, but could easily be shifted elsewhere and pushed to artifact registry, which is all cloud run requires.

The firebase and gh-pages steps are trivial pushes without anything you'd call a build.

The cloud build is triggered weekly by a cron on my computer somewhere.
