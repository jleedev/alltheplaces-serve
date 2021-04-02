Vector tile server for the [All The Places][1] data.

[1]: https://www.alltheplaces.xyz/

Deploy to Google Cloud Run with

```
gcloud builds submit --tag gcr.io/$PROJECT/alltheplaces
gcloud run deploy --platform managed alltheplaces --image gcr.io/$PROJECT/alltheplaces --memory 1024Mi
```

Or build and run with

```
python3 update.py > output.geojson
ogr2ogr output.gpkg output.geojson
docker-compose up
```

