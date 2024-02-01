locals {
  tags = merge(var.tags, { module = "amazon-mq" })
  subnet_ids = (var.deployment_mode == "SINGLE_INSTANCE" ? [var.vpc_subnet_ids[0]] : [
    var.vpc_subnet_ids[0],
    var.vpc_subnet_ids[1],
  ])
  username = try(coalesce(var.username), random_string.user.result)
  password = try(coalesce(var.password), random_password.password.result)
}

# Generate username
resource "random_string" "user" {
  length           = 8
  special          = true
  numeric          = false
  override_special = "-._~"
}

# Generate password
resource "random_password" "password" {
  length           = 16
  special          = true
  lower            = true
  upper            = true
  numeric          = true
  override_special = "!@#$%&*()-_+.{}<>?"
}

resource "aws_mq_broker" "mq" {
  broker_name        = var.name
  engine_type        = var.engine_type
  engine_version     = var.engine_version
  host_instance_type = var.host_instance_type
  apply_immediately  = var.apply_immediately
  deployment_mode    = (var.engine_type == "RabbitMQ" && var.deployment_mode == "ACTIVE_STANDBY_MULTI_AZ") ? "CLUSTER_MULTI_AZ" : (var.engine_type == "ActiveMQ" && var.deployment_mode == "CLUSTER_MULTI_AZ") ? "ACTIVE_STANDBY_MULTI_AZ" : var.deployment_mode
  storage_type       = var.engine_type == "RabbitMQ" ? "ebs" : var.deployment_mode == "ACTIVE_STANDBY_MULTI_AZ" ? "efs" : var.storage_type
  # only ebs is supported for RabbitMQ
  authentication_strategy = var.engine_type == "RabbitMQ" ? "simple" : var.authentication_strategy
  # ldap is not supported for RabbitMQ
  publicly_accessible = var.publicly_accessible
  security_groups     = [aws_security_group.mq.id]
  subnet_ids          = local.subnet_ids
  configuration {
    id       = var.engine_type == "ActiveMQ" ? aws_mq_configuration.activemq_configuration[0].id : aws_mq_configuration.rabbitmq_configuration[0].id
    revision = var.engine_type == "ActiveMQ" ? aws_mq_configuration.activemq_configuration[0].latest_revision : aws_mq_configuration.rabbitmq_configuration[0].latest_revision
  }
  encryption_options {
    kms_key_id        = var.kms_key_id
    use_aws_owned_key = false
  }
  logs {
    audit   = var.engine_type == "RabbitMQ" ? null : true
    general = true
  }
  user {
    password       = local.password
    username       = local.username
    console_access = true
    groups         = []
  }
  tags = local.tags
}

# MQ configuration only if engine type is ActiveMQ
resource "aws_mq_configuration" "activemq_configuration" {
  count          = var.engine_type == "ActiveMQ" ? 1 : 0
  description    = "ArmoniK ActiveMQ Configuration"
  name           = var.name
  engine_type    = var.engine_type
  engine_version = var.engine_version
  data           = <<DATA
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<broker xmlns="http://activemq.apache.org/schema/core">
  <persistenceAdapter>
    <kahaDB concurrentStoreAndDispatchQueues="false" journalDiskSyncInterval="10000" journalDiskSyncStrategy="periodic" preallocationStrategy="zeros"/>
  </persistenceAdapter>
  <systemUsage>
    <systemUsage sendFailIfNoSpace="true" sendFailIfNoSpaceAfterTimeout="60000">
      <memoryUsage>
        <memoryUsage percentOfJvmHeap="70"/>
      </memoryUsage>
    </systemUsage>
  </systemUsage>
  <destinationPolicy>
    <policyMap>
      <policyEntries>
        <policyEntry prioritizedMessages="true" queue="&gt;"/>
        <policyEntry topic="&gt;">
          <!-- The constantPendingMessageLimitStrategy is used to prevent
            slow topic consumers to block producers and affect other consumers
            by limiting the number of messages that are retained
            For more information, see:
            http://activemq.apache.org/slow-consumer-handling.html
        -->
          <pendingMessageLimitStrategy>
            <constantPendingMessageLimitStrategy limit="100000000"/>
          </pendingMessageLimitStrategy>
        </policyEntry>
      </policyEntries>
    </policyMap>
  </destinationPolicy>
  <transportConnectors>
    <!-- DOS protection, limit concurrent connections to 1000 and frame size to 100MB -->
    <!--
    <transportConnector name="openwire" uri="tcp://0.0.0.0:61616?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
    <transportConnector name="amqp" uri="amqp://0.0.0.0:5672?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
    <transportConnector name="stomp" uri="stomp://0.0.0.0:61613?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
    <transportConnector name="mqtt" uri="mqtt://0.0.0.0:1883?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
    <transportConnector name="ws" uri="ws://0.0.0.0:61614?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
    -->
    <transportConnector name="openwire" uri="amqp+ssl://0.0.0.0:5672?maximumConnections=1000000&amp;wireFormat.maxFrameSize=1048576000" updateClusterClients="true" rebalanceClusterClients="true" updateClusterClientsOnRemove="true"/>

  </transportConnectors>
</broker>
DATA
  tags           = local.tags
}

# MQ configuration only if engine type is RabbitMQ
resource "aws_mq_configuration" "rabbitmq_configuration" {
  count          = var.engine_type == "RabbitMQ" ? 1 : 0
  description    = "ArmoniK RabbitMQ Configuration"
  name           = var.name
  engine_type    = var.engine_type
  engine_version = var.engine_version
  data           = <<DATA
## DEFAULT SETTINGS ARE NOT MEANT TO BE TAKEN STRAIGHT INTO PRODUCTION
## see https://www.rabbitmq.com/configure.html for further information
## on configuring RabbitMQ
# https://github.com/rabbitmq/rabbitmq-server/blob/main/deps/rabbit/docs/rabbitmq.conf.example
# https://github.com/rabbitmq/rabbitmq-server/blob/main/deps/rabbit/docs/advanced.config.example
# Default RabbitMQ delivery acknowledgement timeout is 30 minutes
consumer_timeout = 1800000

## allow access to the guest user from anywhere on the network
## https://www.rabbitmq.com/access-control.html#loopback-users
## https://www.rabbitmq.com/production-checklist.html#users
loopback_users.guest = false

## Send all logs to stdout/TTY. Necessary to see logs when running via
## a container
log.console = true

## Defines the threshold of RAM using at which publishers to the queue are throttled
## https://www.rabbitmq.com/memory.html
vm_memory_high_watermark.relative = 0.75

## Defines the threshold of memory using at which publishers to the queue are throttled
## https://www.rabbitmq.com/disk-alarms.html
disk_free_limit.relative = 0.75

## TLS listeners are configured in the same fashion as TCP listeners,
## including the option to control the choice of interface.
##
# listeners.ssl.default = 5671
DATA
  tags           = local.tags
}

# MQ security group
resource "aws_security_group" "mq" {
  name        = "${var.name}-sg"
  description = "Allow Amazon MQ inbound traffic on port 5672"
  vpc_id      = var.vpc_id
  ingress {
    description = "tcp from Amazon MQ"
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
  }
  dynamic "ingress" {
    for_each = var.publicly_accessible && var.engine_type == "ActiveMQ" ? [1] : []
    content {
      description = "Web console for Amazon MQ broker ActiveMQ"
      from_port   = 8162
      to_port     = 8162
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  dynamic "ingress" {
    for_each = var.publicly_accessible && var.engine_type == "RabbitMQ" ? [1] : []
    content {
      description = "Web console for Amazon MQ broker RabbitMQ"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  dynamic "ingress" {
    for_each = var.publicly_accessible && var.engine_type == "RabbitMQ" ? [1] : []
    content {
      description = "Web console for Amazon MQ broker RabbitMQ"
      from_port   = 15672
      to_port     = 15672
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  /*dynamic "ingress" {
    for_each = var.publicly_accessible ? [1] : []
    content {
      description = "OpenWire for Amazon MQ"
      from_port   = 61616
      to_port     = 61616
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  */
  tags = local.tags
}

# IMA
data "aws_iam_policy_document" "mq_logs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
      "logs:PutRetentionPolicy",
    ]
    resources = ["arn:aws:logs:*:*:*:/aws/amazonmq/*"]
    principals {
      identifiers = ["mq.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "mq_logs_publishing_policy" {
  policy_document = data.aws_iam_policy_document.mq_logs_policy.json
  policy_name     = "mq-logs-publishing-policy"
}
