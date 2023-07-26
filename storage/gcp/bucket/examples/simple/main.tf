module "simple_bucket_example" {
    source           = "../../../bucket"
    project_id       = "armonik-gcp-13469"
    credentials_file = "~/.config/gcloud/application_default_credentials.json"
    bucket_name      = "my-awesome-bucket-132456789"
    region           = "europe-west9"
    
}