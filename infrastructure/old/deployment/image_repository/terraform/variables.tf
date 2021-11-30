# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

variable "region" {
  description = "the region where the ECR repository will be created"
  default = "eu-west-1"
}

variable "image_to_copy" {
  description = "contains the list of third party images to copy (and where to copy them)"
  type = map
}

variable "repository" {
  description = "contains the list of ECR repository to create"
  type =  list
}

variable "lambda_runtime" {
  description = "runtime used for the custom worker"
  default = "python3.7"
  type =  string
}

variable "kms_key_arn" {
  description = "KMS key ARN for ECR repositories"
  type =  string
}