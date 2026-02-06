module "authentication" {
  count  = can(try(coalesce(var.authentication))) ? 1 : 0
  source = "../authentication"
  authentication = {
    trusted_common_names = try(var.authentication.trusted_common_names, null)
    datafile             = try(var.authentication.datafile, null)
    permissions          = local.permissions
  }
  client_certificates   = tls_locally_signed_cert.ingress_client_certificate
  client_certs_requests = tls_cert_request.ingress_client_cert_request
}

locals {
  permissions = try(coalesce(var.authentication.permissions), local.default_permissions)
  default_permissions = tomap({
    "Submitter" = [
      "Submitter:GetServiceConfiguration",
      "Submitter:CancelSession",
      "Submitter:CancelTasks",
      "Submitter:CreateSession",
      "Submitter:CreateSmallTasks",
      "Submitter:CreateLargeTasks",
      "Submitter:CountTasks",
      "Submitter:TryGetResultStream",
      "Submitter:WaitForCompletion",
      "Submitter:TryGetTaskOutput",
      "Submitter:WaitForAvailability",
      "Submitter:GetTaskStatus",
      "Submitter:GetResultStatus",
      "Submitter:ListTasks",
      "Submitter:ListSessions",
      "Sessions:CancelSession",
      "Sessions:GetSession",
      "Sessions:ListSessions",
      "Sessions:CreateSession",
      "Sessions:PauseSession",
      "Sessions:CloseSession",
      "Sessions:PurgeSession",
      "Sessions:DeleteSession",
      "Sessions:ResumeSession",
      "Sessions:StopSubmission",
      "Tasks:GetTask",
      "Tasks:ListTasks",
      "Tasks:GetResultIds",
      "Tasks:CancelTasks",
      "Tasks:CountTasksByStatus",
      "Tasks:ListTasksDetailed",
      "Tasks:SubmitTasks",
      "Results:GetOwnerTaskId",
      "Results:ListResults",
      "Results:CreateResultsMetaData",
      "Results:CreateResults",
      "Results:DeleteResultsData",
      "Results:DownloadResultData",
      "Results:GetServiceConfiguration",
      "Results:UploadResultData",
      "Results:GetResult",
      "Results:ImportResultsData",
      "Applications:ListApplications",
      "Events:GetEvents",
      "General:Impersonate",
      "Partitions:GetPartition",
      "Partitions:ListPartitions",
      "Versions:ListVersions",
      "HealthChecks:CheckHealth"
    ]
    "Monitoring" = [
      "Submitter:GetServiceConfiguration",
      "Submitter:CountTasks",
      "Submitter:GetTaskStatus",
      "Submitter:GetResultStatus",
      "Submitter:ListTasks",
      "Submitter:ListSessions",
      "Sessions:GetSession",
      "Sessions:ListSessions",
      "Tasks:GetTask",
      "Tasks:ListTasks",
      "Tasks:GetResultIds",
      "Tasks:CountTasksByStatus",
      "Tasks:ListTasksDetailed",
      "Results:GetOwnerTaskId",
      "Results:ListResults",
      "Results:GetServiceConfiguration",
      "Results:GetResult",
      "Applications:ListApplications",
      "Events:GetEvents",
      "Partitions:GetPartition",
      "Partitions:ListPartitions",
      "Versions:ListVersions",
      "HealthChecks:CheckHealth"
    ]
  })
}
