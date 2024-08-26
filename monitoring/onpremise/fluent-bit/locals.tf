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
  fluent_bit_node_selector_keys                 = keys(var.node_selector)
  fluent_bit_node_selector_values               = values(var.node_selector)

  # Seq
  seq_host    = try(var.seq.host, "")
  seq_port    = try(var.seq.port, "")
  seq_enabled = tobool(try(var.seq.enabled, false))

  # CloudWatch
  cloudwatch_name    = try(var.cloudwatch.name, "")
  cloudwatch_region  = try(var.cloudwatch.region, "")
  cloudwatch_enabled = tobool(try(var.cloudwatch.enabled, false))

  #S3
  s3_name    = try(var.s3.name, "armonik-logs")
  s3_region  = try(var.s3.region, "eu-west-3")
  s3_prefix  = try(var.s3.prefix, "main")
  s3_enabled = tobool(try(var.s3.enabled, false))
}
