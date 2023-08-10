node_pools = {
    test = {
      name               = "default-node-pool"
      machine_type       = "e2-medium"
      node_locations     = "us-central1-b,us-central1-c"
      min_count          = 1
      max_count          = 100
      local_ssd_count    = 0
      spot               = false
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      auto_repair        = true
      auto_upgrade       = true
      service_account    = "tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"
      preemptible        = false
      # initial_node_count = 0
      # taint=[{
      #   key    = "default-node-pool"
      #   value  = true
      #   effect = "PREFER_NO_SCHEDULE"
      # }]
    }
    test-3 = {
      name               = "default-node-pool-3"
      machine_type       = "e2-medium"
      node_locations     = "us-central1-b,us-central1-c"
      min_count          = 1
      max_count          = 100
      local_ssd_count    = 0
      spot               = false
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      auto_repair        = true
      auto_upgrade       = true
      service_account    = "tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"
      preemptible        = false
      initial_node_count = 0
      taint=[{
        key    = "default-node-pool-3"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      }]
    }  
    test-2 = {
      name               = "default-node-pool-2"
      machine_type       = "e2-medium"
      node_locations     = "us-central1-b,us-central1-c"
      min_count          = 1
      max_count          = 100
      local_ssd_count    = 0
      spot               = false
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      auto_repair        = true
      auto_upgrade       = true
      service_account    = "tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"
      preemptible        = false
      initial_node_count = 0
      taint=[{
        key    = "default-node-pool-2"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      }]
    }
    
}


  service_account        = "tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"
  project             = "armonik-gcp-13469"
  ca_certificate="LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUVMVENDQXBXZ0F3SUJBZ0lSQUpQb0tJWkk4Y3FZc1VXUzlPeU5Zc2d3RFFZSktvWklodmNOQVFFTEJRQXcKTHpFdE1Dc0dBMVVFQXhNa01ETTJPRGN6TVdZdE5XVmpaUzAwWlRRd0xUaGxPV1F0TXpjNE5HUmpOakF3WkdRdwpNQ0FYRFRJek1EZ3dNVEV6TURFeE5Gb1lEekl3TlRNd056STBNVFF3TVRFMFdqQXZNUzB3S3dZRFZRUURFeVF3Ck16WTROek14WmkwMVpXTmxMVFJsTkRBdE9HVTVaQzB6TnpnMFpHTTJNREJrWkRBd2dnR2lNQTBHQ1NxR1NJYjMKRFFFQkFRVUFBNElCandBd2dnR0tBb0lCZ1FDWVFkdVBHNmErdXE2T2J1TlBPSFRrL25WQkFzQkVLVjQrV2VOcQpMdkc2dGVuYXBtMGc4U21oZHRkWm9tOEVvcW51cTNsQjBnT2hBVndnTTc1bmdEelJEUjlXVVJLVVVGdzZxSDRaCnhueHltSy92Z25FZjhZc1RqbHF3TVZNYVhkUERYSFg2enAyRUtaWHJRaGx6VmFFWXFkSUZrT29lS3dkM0ZIZlMKbFpHUHhXUWhHZm9sWU9Ldm05enkzSEczVEw4a0ZwRXJ3TmFGbnQ5VXErSjZFRkkvWlBzakJ5WFgxRkZSYXRJWQpSZzlmQlA4eHNOMlpXNlQxMTVXZDZGZE9VYk1CUml0WlZEVmI3NUorSHJmTjVvUGgxeUlHbWQ2Y2ljVjVlSk9lClkwWkFiWVRySVZVSFFoNkhUWmkvZUMzNllCMTd5WWQ4U1FPd0lROGdlNlpiSTd3MW1ndlk0dE9mTm5UOGRQOEoKWU1iRFR1aU1SRXQ2cXN3bWwwZUd0VWlLVEcvRUQ0b2RrS014WmhMZHhNVjl0bHhKWFhFK0Z0RHFQazNIR2xFMApCMDREaEFYRnR1ZlZhbkhmNHo2MlUvb1lSL2d5K05jNFRHSlFrekcrNGM5S1d4WS9oYnluMy95cHh0azFYa2lnCk1HRTZlZW91SXI2Q0RBcTBNMHJxVG9kQ0MxMENBd0VBQWFOQ01FQXdEZ1lEVlIwUEFRSC9CQVFEQWdJRU1BOEcKQTFVZEV3RUIvd1FGTUFNQkFmOHdIUVlEVlIwT0JCWUVGQTdVYU45SjZXRTMvMG1LdlpzY1EzU2JwZ2ZJTUEwRwpDU3FHU0liM0RRRUJDd1VBQTRJQmdRQXZGNDgxZHJBY3N6SVNBMEMrVzg1dkxmK1ZUSDFENWxTSEVSeWZ5b251CkNURkZXWU9idmFUQWM1UVAzc1p5YUhXemhlajdBVVlSN3IyU05yei9nbllWUDhIWXV6dm5rSytPVCs2RFc1eVcKNjcva3EyYVIvQjhLWnBBdEcvcjNoc0pmOUN4Q1FBdHBvQnlJSCtYZEFINW1JWEl5Y3VtTHpGYkZVdHpPRXY0QwpVM3M1TWlDeUZPaGFwa0VXK0JxQ0xTZEljSFZmYnU0Y0R1dkRGd3J1MTM2KzVwbG9yQmlKSFo2V2tEdCs4eGpYCjRrSkxuWTdvalFpRE5aS2VNcFVBUjg5c2cxekNLOG44d1JRclpxL2t0WkNBWXNRbWVNLzRkTFczTSttYmFxV3AKWEM3TGFHYzV2Q0I5aGpLMElhOFl1WW5hT09UbVRvMkVSbUxyaXBlVXl1VysrQzlLdzBtTEdqZy9pZm42UDFMeQpuaDgyY01LU3ZZa3pNODc1ajUrVitHeGpTQUpNTzUwek1hQVh6QWUyWUlZZzJkYk9sbXZsY1RuUDdRNm4zN3N6CjZtWjRlblBOUzFZK21NOEdJbXVaSEc2NW03VEVpdEVZc2F6WFk0YXhNUTBxcjM4dEk3UG1xbWJ0bnZxd3RDcEwKc1lyOEVUWHJEOVZzNUNsN1pkWmh0Rzg9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
  endpoint="35.238.234.244"
  cluster_name="gke-on-vpc-cluster"
  location = "us-central1"