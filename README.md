Deploy to Google Cloud Run with

```
gcloud builds submit --tag gcr.io/$PROJECT/alltheplaces
gcloud run deploy --platform managed alltheplaces --image gcr.io/$PROJECT/alltheplaces --memory 1024Mi
```

