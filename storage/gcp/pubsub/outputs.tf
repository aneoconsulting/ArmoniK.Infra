output "env" {
  description = "Elements to be set as environment variables"
  value = ({
    "Components__QueueAdaptorSettings__ClassName"           = "ArmoniK.Core.Adapters.PubSub.QueueBuilder"
    "Components__QueueAdaptorSettings__AdapterAbsolutePath" = "/adapters/queue/pubsub/ArmoniK.Core.Adapters.PubSub.dll"
    "PubSub__ProjectId"                                     = var.project_id
    "PubSub__KmsKeyName"                                    = var.kms_key_id
  })
}
