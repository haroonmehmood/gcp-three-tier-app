terraform {
  backend "gcs" {
    # GCS bucket names are globally unique across all of Google Cloud, so this
    # must be a bucket you own. Create it before the first `terraform init`:
    #   gcloud storage buckets create gs://<YOUR-BUCKET> --location=us-central1 --uniform-bucket-level-access
    #   gcloud storage buckets update gs://<YOUR-BUCKET> --versioning
    bucket = "three-tier-app-haroon-tfstate"
    prefix = "three-tier-app"
  }
}
