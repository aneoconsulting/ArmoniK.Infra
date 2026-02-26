# Certificate Authority
resource "tls_private_key" "ca" {
  count     = var.tls.self_managed ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  count             = var.tls.self_managed ? 1 : 0
  private_key_pem   = tls_private_key.ca[0].private_key_pem
  is_ca_certificate = true

  validity_period_hours = var.tls.validity_period_hours

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]

  subject {
    organization = "ArmoniK Percona MongoDB Root (NonTrusted)"
    common_name  = "ArmoniK Percona MongoDB Root (NonTrusted) Private Certificate Authority"
    country      = "France"
  }
}

# External TLS certificate (clients)
resource "tls_private_key" "server" {
  count     = var.tls.self_managed ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "server" {
  count           = var.tls.self_managed ? 1 : 0
  private_key_pem = tls_private_key.server[0].private_key_pem

  subject {
    country     = "France"
    common_name = local.mongodb_dns
  }

  dns_names = local.tls_server_sans
}

resource "tls_locally_signed_cert" "server" {
  count              = var.tls.self_managed ? 1 : 0
  cert_request_pem   = tls_cert_request.server[0].cert_request_pem
  ca_private_key_pem = tls_private_key.ca[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca[0].cert_pem

  validity_period_hours = var.tls.validity_period_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "any_extended",
  ]
}

# Internal TLS certificate (intra-cluster replication)
resource "tls_private_key" "internal" {
  count     = var.tls.self_managed ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "internal" {
  count           = var.tls.self_managed ? 1 : 0
  private_key_pem = tls_private_key.internal[0].private_key_pem

  subject {
    country     = "France"
    common_name = "${local.cluster_release_name}-internal"
  }

  dns_names = local.tls_internal_sans
}

resource "tls_locally_signed_cert" "internal" {
  count              = var.tls.self_managed ? 1 : 0
  cert_request_pem   = tls_cert_request.internal[0].cert_request_pem
  ca_private_key_pem = tls_private_key.ca[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca[0].cert_pem

  validity_period_hours = var.tls.validity_period_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "any_extended",
  ]
}



locals {
  tls_shards_count = (
    var.sharding != null
    ? var.sharding.shards_quantity
    : 1
  )

  # Short suffixes for each sharded component, e.g. ["rs0","rs1","rs2"]
  tls_rs_names  = [for i in range(local.tls_shards_count) : "rs${i}"]
  tls_cfg_names = [for i in range(local.tls_shards_count) : "cfg${i}"]

  # External cert SANs — service-level names used by clients and the operator
  tls_server_sans = concat(
    [local.mongodb_dns],
    # One entry per replica-set shard service
    flatten([
      for rs in local.tls_rs_names : [
        "${local.cluster_release_name}-${rs}.${var.namespace}.svc.cluster.local",
        "${local.cluster_release_name}-${rs}.${var.namespace}.svc",
        "${local.cluster_release_name}-${rs}.${var.namespace}",
        "${local.cluster_release_name}-${rs}",
      ]
    ]),
    # Mongos (only present when sharding is enabled, harmless otherwise)
    [
      "${local.cluster_release_name}-mongos.${var.namespace}.svc.cluster.local",
      "${local.cluster_release_name}-mongos.${var.namespace}.svc",
      "${local.cluster_release_name}-mongos.${var.namespace}",
      "${local.cluster_release_name}-mongos",
    ],
    # Config servers (one per shard when sharding is enabled)
    flatten([
      for cfg in local.tls_cfg_names : [
        "${local.cluster_release_name}-${cfg}.${var.namespace}.svc.cluster.local",
        "${local.cluster_release_name}-${cfg}.${var.namespace}.svc",
        "${local.cluster_release_name}-${cfg}.${var.namespace}",
        "${local.cluster_release_name}-${cfg}",
      ]
    ]),
    ["localhost"],
  )

  # Internal cert SANs — wildcard per headless service so every pod matches
  # Pod DNS pattern: <pod>.<cluster>-<rs>.<namespace>.svc.cluster.local
  tls_internal_sans = concat(
    flatten([
      for rs in local.tls_rs_names : [
        "*.${local.cluster_release_name}-${rs}.${var.namespace}.svc.cluster.local",
      ]
    ]),
    flatten([
      for cfg in local.tls_cfg_names : [
        "*.${local.cluster_release_name}-${cfg}.${var.namespace}.svc.cluster.local",
      ]
    ]),
    [
      "*.${local.cluster_release_name}-mongos.${var.namespace}.svc.cluster.local",
      "localhost",
    ],
  )
}
