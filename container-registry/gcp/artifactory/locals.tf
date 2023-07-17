
# data "gcp_caller_identity" "current" {}


# data "gcp_region" "current" {}

# locals {
#   region = data.gcp_region.current.name
#   tags   = merge({ module = "ar" }, var.tags)
# }


locals {
  # flatten ensures that this local value is a flat list of objects, rather
  # than a list of lists of objects.
  repository_images = flatten([
    for repository in var.repositories : [
      for image in repository.images : {
        repository_name     = repository.artifact_repository_name
        image_name          = image.image
        image_tag           = image.tag
      }
    ]
  ])
  
  location = (var.zone == null || var.zone == "") ? var.region : "${var.region}-${var.zone}"
}

