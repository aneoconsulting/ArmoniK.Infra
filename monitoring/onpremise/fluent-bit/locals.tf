locals {
  # Fluent-bit
  # tflint-ignore: terraform_unused_declarations
  fluent_bit_state_hostpath                     = try(var.fluent_bit.fluent_bit_state_hostpath, "/var/fluent-bit/state")
  fluent_bit_container_name                     = try(var.fluent_bit.container_name, "fluent-bit")
  fluent_bit_image                              = try(var.fluent_bit.image, "fluent/fluent-bit")
  fluent_bit_tag                                = try(var.fluent_bit.tag, "1.3.11")
  fluent_bit_is_daemonset                       = tobool(try(var.fluent_bit.is_daemonset, false))
  fluent_bit_parser                             = try(var.fluent_bit.parser)
  fluent_bit_http_server                        = try(var.fluent_bit.http_server, "Off")
  fluent_bit_http_port                          = try(var.fluent_bit.http_port, "")
  fluent_bit_read_from_head                     = try(var.fluent_bit.read_from_head, "On")
  fluent_bit_read_from_tail                     = try(var.fluent_bit.read_from_tail, "Off")
  fluent_bit_image_pull_secrets                 = try(var.fluent_bit.image_pull_secrets, "")
  fluent_bit_var_lib_docker_containers_hostpath = try(var.fluent_bit.var_lib_docker_containers_hostpath, "/var/lib/docker/containers")
  fluent_bit_run_log_journal_hostpath           = try(var.fluent_bit.run_log_journal_hostpath, "/run/log/journal")
  node_selector = merge(
    {
      "kubernetes.io/os" = "linux"
    },
    var.node_selector
  )
  node_selector_windows = merge(
    {
      "kubernetes.io/os"   = "windows"
      "kubernetes.io/arch" = "amd64"
    },
    var.node_selector_windows
  )
  # tflint-ignore: terraform_unused_declarations
  fluent_bit_windows_state_hostpath     = try(var.fluent_bit_windows.fluent_bit_state_hostpath, "C:\\var\\fluent-bit\\state")
  fluent_bit_windows_container_name     = try(var.fluent_bit_windows.container_name, "fluent-bit")
  fluent_bit_windows_image              = try(var.fluent_bit_windows.image, "fluent/fluent-bit")
  fluent_bit_windows_tag                = try(var.fluent_bit_windows.tag, "windows-2022-3.2.0")
  fluent_bit_windows_is_daemonset       = tobool(try(var.fluent_bit_windows.is_daemonset, false))
  fluent_bit_windows_parser             = try(var.fluent_bit_windows.parser, "")
  fluent_bit_windows_http_server        = try(var.fluent_bit_windows.http_server, "Off")
  fluent_bit_windows_http_port          = try(var.fluent_bit_windows.http_port, "")
  fluent_bit_windows_read_from_head     = try(var.fluent_bit_windows.read_from_head, "On")
  fluent_bit_windows_read_from_tail     = try(var.fluent_bit_windows.read_from_tail, "Off")
  fluent_bit_windows_image_pull_secrets = try(var.fluent_bit_windows.image_pull_secrets, "")
  # tflint-ignore: terraform_unused_declarations
  fluent_bit_windows_var_lib_docker_containers_hostpath = try(var.fluent_bit_windows.var_lib_docker_containers_hostpath, "C:\\var\\lib\\docker\\containers")
  # tflint-ignore: terraform_unused_declarations
  fluent_bit_windows_run_log_journal_hostpath = try(var.fluent_bit_windows.run_log_journal_hostpath, "C\\run\\log\\journal")

  #windows
  fluent_bit_kube_ca_file_windows           = "C:\\var\\run\\secrets\\kubernetes.io\\serviceaccount\\ca.crt"
  fluent_bit_kube_token_file_windows        = "C:\\var\\run\\secrets\\kubernetes.io\\serviceaccount\\token"
  fluent_bit_input_kube_path_windows        = "C:\\var\\log\\containers\\control-plane*.log, C:\\var\\log\\containers\\compute-plane*.log"
  fluent_bit_input_application_path_windows = "C:\\var\\log\\containers\\control-plane*.log, C:\\var\\log\\containers\\compute-plane*.log, C:\\var\\log\\containers\\ingress*.log, C:\\var\\log\\containers\\mongodb*.log, C:\\var\\log\\containers\\keda*.log"
  fluent_bit_input_s3_path_windows          = "C:\\var\\log\\containers\\control-plane*.log, C:\\var\\log\\containers\\compute-plane*.log, C:\\var\\log\\containers\\ingress*.log, C:\\var\\log\\containers\\mongodb*.log, C:\\var\\log\\containers\\keda*.log"
  fluent_bit_input_path_windows             = "C:\\var\\log\\containers\\"
  windows_and_daemonset                     = (local.fluent_bit_windows_is_daemonset && length(var.node_selector_windows) > 0)

  #linux
  fluent_bit_kube_ca_file           = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
  fluent_bit_kube_token_file        = "/var/run/secrets/kubernetes.io/serviceaccount/token"
  fluent_bit_input_kube_path        = "/var/log/containers/control-plane*.log, /var/log/containers/compute-plane*.log"
  fluent_bit_input_application_path = "/var/log/containers/control-plane*.log, /var/log/containers/compute-plane*.log, /var/log/containers/ingress*.log, /var/log/containers/mongodb*.log, /var/log/containers/keda*.log"
  fluent_bit_input_s3_path          = "/var/log/containers/control-plane*.log, /var/log/containers/compute-plane*.log, /var/log/containers/ingress*.log, /var/log/containers/mongodb*.log, /var/log/containers/keda*.log"
  fluent_bit_input_path             = "/var/log/containers/"

  # Seq
  seq_host    = try(var.seq.host, "")
  seq_port    = try(var.seq.port, "")
  seq_enabled = tobool(try(var.seq.enabled, false))

  # CloudWatch
  cloudwatch_name    = try(var.cloudwatch.name, "")
  cloudwatch_region  = try(var.cloudwatch.region, "")
  cloudwatch_enabled = tobool(try(var.cloudwatch.enabled, false))

  #S3
  s3_name       = try(var.s3.name, "armonik-logs")
  s3_region     = try(var.s3.region, "eu-west-3")
  s3_key_format = try(var.s3.s3_key_format, "/main/$TAG[4]_$UUID")
  s3_enabled    = tobool(try(var.s3.enabled, false))
}
