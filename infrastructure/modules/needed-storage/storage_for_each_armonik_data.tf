locals {
  allowed_storage = {
    object         = [
      "MongoDB",
      "Redis"
    ],
    table          = [
      "MongoDB"
    ],
    queue          = [
      "MongoDB",
      "Amqp"
    ],
    lease_provider = [
      "MongoDB"
    ],
    shared         = [
      "HostPath",
      "NFS",
      "AWS_EBS"
    ],
    external       = [
      "Redis"
    ]
  }
}