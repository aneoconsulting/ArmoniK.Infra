output "armonik_versions" {
  description = "Versions of all the ArmoniK components"
  value       = var.armonik_versions
}

output "image_tags" {
  description = "Tags of images used"
  value = merge(concat(
    [for component, images in var.armonik_images :
      { for image in images : image => var.armonik_versions[component] }
    ],
    [var.image_tags]
  )...)
}
