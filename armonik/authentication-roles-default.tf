resource "random_string" "common_name" {
  for_each = toset(["submitter", "monitoring", "loadbalancer"])
  length   = 16
  special  = false
  numeric  = false
}

locals {

  custom_auth_file  = can(coalesce(var.authentication.authentication_datafile)) ? jsondecode(file(var.authentication.authentication_datafile)) : null
  custom_users_list = try(local.custom_auth_file.users_list, null)
  custom_roles_list = try(local.custom_auth_file.roles_list, null)


  # Ignore custom users named 'submitter' or 'monitoring'
  provided_users_roles_map = {
    for obj in local.custom_users_list :
    obj.Username => obj.Roles if !contains(["submitter", "monitoring"], obj.Username)
  }

  username_roles_map = merge({
    submitter  = ["Submitter"]
    monitoring = ["Monitoring"]
    }, var.load_balancer != null && !can(try(local.provided_users_roles_map["loadbalancer"])) ? {
    loadbalancer = ["Submitter"]
  } : null, local.provided_users_roles_map)

  username_common_name_map = merge({
    submitter  = random_string.common_name["submitter"].result
    monitoring = random_string.common_name["monitoring"].result
    }, can(try(local.username_roles_map["loadbalancer"])) ? {
    loadbalancer = random_string.common_name["loadbalancer"].result
  } : null)

  generate_certs_for = {
    for u, cn in local.username_common_name_map :
    u => {
      common_name = cn
    }
  }

  provided_roles_permissions_map = {
    for obj in local.custom_roles_list :
    obj.RoleName => obj.Permissions
  }

  default_roles_permissions_map = tomap({
    Submitter = [
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
    Monitoring = [
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
  final_roles_permissions_map = merge(local.default_roles_permissions_map, local.provided_roles_permissions_map)
}
