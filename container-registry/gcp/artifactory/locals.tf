
# data "gcp_caller_identity" "current" {}


# data "gcp_region" "current" {}

# locals {
#   region = data.gcp_region.current.name
#   tags   = merge({ module = "ar" }, var.tags)
# }


locals {
  location = (var.zone == null || var.zone == "") ? var.region : "${var.region}-${var.zone}"
}

