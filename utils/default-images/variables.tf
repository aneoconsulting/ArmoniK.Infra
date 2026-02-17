variable "armonik_versions" {
  description = "Versions of all the ArmoniK components"
  type        = map(string)
}

variable "armonik_images" {
  description = "Image names of all the ArmoniK components"
  type        = map(set(string))
}

variable "image_tags" {
  description = "Tags of images used"
  type        = map(string)
}
