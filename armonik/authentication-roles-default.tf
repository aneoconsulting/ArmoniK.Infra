resource "random_string" "common_name" {
  for_each = toset(["submitter", "monitoring", "loadbalancer"])
  length   = 16
  special  = false
  numeric  = false
}

locals {
  username_roles_map = merge({
    submitter  = ["Submitter"]
    monitoring = ["Monitoring"]
    }, var.load_balancer != null ? {
    loadbalancer = ["Submitter"]
  } : null)

  username_common_name_map = merge({
    submitter  = random_string.common_name["submitter"].result
    monitoring = random_string.common_name["monitoring"].result
    }, var.load_balancer != null ? {
    loadbalancer = random_string.common_name["loadbalancer"].result
  } : null)

  generate_certs_for = {
    for u, cn in local.username_common_name_map :
    u => {
      common_name = cn
    }
  }

  role_permissions_map = tomap({
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
