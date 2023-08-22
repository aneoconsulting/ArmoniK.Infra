output "default_sqs_queue_id" {
  description = "The URL for the created Amazon SQS queue"
  value       = module.default_sqs.queue_id
}

output "default_sqs_queue_arn" {
  description = "The ARN of the SQS queue"
  value       = module.default_sqs.queue_arn
}

output "default_sqs_queue_url" {
  description = "Same as `queue_id`: The URL for the created Amazon SQS queue"
  value       = module.default_sqs.queue_url
}

output "default_sqs_queue_name" {
  description = "The name of the SQS queue"
  value       = module.default_sqs.queue_name
}
