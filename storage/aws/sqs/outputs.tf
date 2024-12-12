output "env" {
  description = "Environment variables to pass to ArmoniK.Core"
  value = {
    "Components__QueueAdaptorSettings__ClassName"           = "ArmoniK.Core.Adapters.SQS.QueueBuilder"
    "Components__QueueAdaptorSettings__AdapterAbsolutePath" = "/adapters/queue/sqs/ArmoniK.Core.Adapters.SQS.dll"
    "SQS__ServiceURL"                                       = "https://sqs.${local.region}.amazonaws.com"
    "SQS__Prefix"                                           = local.prefix
  }
}
