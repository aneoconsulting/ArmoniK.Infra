# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

output "agent_config" {
  description = "file name for the agent configuration"
  value       = abspath(local_file.agent_config_file.filename)
}

output "external_ip" {
  value = module.control_plane.external_ip
}

output "redis_url" {
  value = "${module.control_plane.redis_pod_ip}:${var.redis_port}"
}

output "mongodb_url" {
  value = "mongodb://${module.control_plane.mongodb_pod_ip}:${var.mongodb_port}"
}

output "local_services_url" {
  value = "http://${module.control_plane.local_services_pod_ip}:${var.local_services_port}"
}

output "queue_url" {
  value = "${module.control_plane.queue_pod_ip}:${var.queue_port}"
}