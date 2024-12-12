output "env" {
  description = "Environment variables to pass to ArmoniK.Core"
  value = {
    "Components__QueueAdaptorSettings__ClassName"           = "ArmoniK.Contrib.Plugin.SQS.QueueBuilder"
    "Components__QueueAdaptorSettings__AdapterAbsolutePath" = "/adapters/queue/sqs/ArmoniK.Core.Adapters.SQS.dll"
    "SQS__ServiceURL"                                       = "https://sqs.${var.region}.amazonaws.com"
    "SQS__Prefix"                                           = local.prefix
  }
}
