resource "kubernetes_job" "authentication_in_database" {
  depends_on = [
    kubernetes_service.ingress
  ]
  count = local.authentication_require_authentication ? 1 : 0
  metadata {
    name      = "authentication-in-database"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      service = "authentication-in-database"
      type    = "monitoring"
    }
  }
  spec {
    template {
      metadata {
        name = "authentication-in-database"
        labels = {
          app     = "armonik"
          service = "authentication-in-database"
          type    = "monitoring"
        }
      }
      spec {
        node_selector = local.job_authentication_in_database_node_selector
        dynamic "toleration" {
          for_each = (local.job_authentication_in_database_node_selector != {} ? [
            for index in range(0, length(local.job_authentication_in_database_node_selector_keys)) : {
              key   = local.job_authentication_in_database_node_selector_keys[index]
              value = local.job_authentication_in_database_node_selector_values[index]
            }
          ] : [])
          content {
            key      = toleration.value.key
            operator = "Equal"
            value    = toleration.value.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = (var.authentication.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.authentication.image_pull_secrets
          }
        }
        restart_policy = "OnFailure" # Always, OnFailure, Never
        container {
          name              = var.authentication.name
          image             = var.authentication.tag != "" ? "${var.authentication.image}:${var.authentication.tag}" : var.authentication.image
          image_pull_policy = var.authentication.image_pull_policy
          command           = ["/bin/bash", "-c", local.authentication_script]

          #env from config
          dynamic "env" {
            for_each = module.job_aggregation.env
            content {
              name  = env.key
              value = env.value
            }
          }

          #env from secret
          dynamic "env" {
            for_each = module.job_aggregation.env_from_secret
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  name = env.value.secret
                  key  = env.value.field
                }
              }
            }
          }

          dynamic "env" {
            for_each = module.job_aggregation.env_from_configmap
            content {
              name = env.key
              value_from {
                config_map_key_ref {
                  name = env.value.configmap
                  key  = env.value.field
                }
              }
            }
          }

          dynamic "env_from" {
            for_each = module.job_aggregation.env_configmap
            content {
              config_map_ref {
                name = env_from.value
              }
            }
          }

          dynamic "env_from" {
            for_each = module.job_aggregation.env_secret
            content {
              secret_ref {
                name = env_from.value
              }
            }
          }

          #mount from conf
          dynamic "volume_mount" {
            for_each = module.job_aggregation.mount_secret
            content {
              mount_path = volume_mount.value.path
              name       = volume_mount.value.secret
              read_only  = true
            }
          }

          dynamic "volume_mount" {
            for_each = module.job_aggregation.mount_configmap
            content {
              name       = volume_mount.value.configmap
              mount_path = volume_mount.value.path
              sub_path   = lookup(volume_mount.value, "subpath", null)
              read_only  = true
            }
          }
        }

        #form conf
        dynamic "volume" {
          for_each = module.job_aggregation.mount_secret
          content {

            name = volume.value.secret
            secret {
              secret_name  = volume.value.secret
              default_mode = volume.value.mode

            }
          }
        }

        dynamic "volume" {
          for_each = module.job_aggregation.mount_configmap
          content {
            name = volume.value.configmap
            config_map {
              name         = volume.value.configmap
              default_mode = volume.value.mode
              dynamic "items" {
                for_each = try(coalesce(volume.value.items), {})
                content {
                  key  = items.key
                  path = items.value.field
                  mode = items.value.mode
                }
              }
            }
          }
        }
      }
    }
    backoff_limit = 5
  }
  wait_for_completion = true
  timeouts {
    create = "2m"
    update = "2m"
  }
}

data "tls_certificate" "certificate_data" {
  for_each = tls_locally_signed_cert.ingress_client_certificate
  content  = each.value.cert_pem
}

locals {
  authentication_data_default = jsonencode({
    certificates_list = [
      for name, cert in data.tls_certificate.certificate_data : {
        Fingerprint = cert.certificates[length(cert.certificates) - 1].sha1_fingerprint,
        CN          = tls_cert_request.ingress_client_cert_request[name].subject[0].common_name,
        Username    = name
      }
    ]
    users_list = [
      for name, cert in data.tls_certificate.certificate_data : {
        Username = name,
        Roles    = [name]
      }
    ]
    roles_list = [
      for name, cert in data.tls_certificate.certificate_data : {
        RoleName    = name,
        Permissions = local.ingress_generated_cert.permissions[name]
      }
    ]
  })
  authentication_data = (
    length(tls_locally_signed_cert.ingress_client_certificate) > 0 ? local.authentication_data_default :
    var.authentication.require_authentication ? file(var.authentication.authentication_datafile) :
    ""
  )

  auth_js = <<EOF
var auth_data = ${local.authentication_data};
var certs_list = auth_data['certificates_list'];
var users_list = auth_data['users_list'];
var roles_list = auth_data['roles_list'];
var aggregation_user = [
  {
    '$lookup': {
      'from': 'RoleData',
      'localField': 'Roles',
      'foreignField': 'RoleName',
      'as': 'RoleIds'
    }
  }, {
    '$project': {
      '_id': 0,
      'Username': 1,
      'Roles': '$RoleIds._id'
    }
  }, {
    '$out': 'UserData'
  }
];
var aggregation_certs = [
  {
    '$lookup': {
      'from': 'UserData',
      'localField': 'Username',
      'foreignField': 'Username',
      'as': 'UserId'
    }
  }, {
    '$match': {
      'UserId': {
        '$ne': null,
        '$not': {
          '$size': 0
        }
      }
    }
  }, {
    '$project': {
      '_id': 0,
      'CN': 1,
      'Fingerprint': 1,
      'UserId': {
        '$arrayElemAt': [
          '$UserId._id', 0
        ]
      }
    }
  }, {
    '$out': 'AuthData'
  }
];

// Drop
db.RoleData.drop();
db.Temp_UserData.drop();
db.Temp_AuthData.drop();
db.UserData.drop();
db.AuthData.drop();

// We need to put the certs and users in temporary tables because inline documents in pipelines are only available in Mongo 5.1
db.RoleData.insertMany(roles_list);
db.Temp_UserData.insertMany(users_list);
db.Temp_AuthData.insertMany(certs_list);

// Then we use the aggregation pipelines to populate the users and certificates with the right objectIds
db.Temp_UserData.aggregate(aggregation_user)
db.Temp_AuthData.aggregate(aggregation_certs)

//We drop the temporary tables
db.Temp_UserData.drop();
db.Temp_AuthData.drop();
  EOF

  authentication_script = <<EOF
#!/bin/bash
mongosh --tlsCAFile $MongoDB__CAFile --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls --username $MongoDB__User --password $MongoDB__Password mongodb://$MongoDB__Host:$MongoDB__Port/database /mongodb/script/initauth.js
EOF
}

resource "kubernetes_config_map" "authmongo" {
  count = local.authentication_require_authentication ? 1 : 0
  metadata {
    name      = "mongodb-script"
    namespace = var.namespace
  }
  data = {
    "initauth.js" = local.auth_js
  }
}

resource "local_sensitive_file" "initial_auth_config" {
  content         = local.authentication_data
  filename        = "${path.root}/generated/certificates/ingress/authentication_conf.json"
  file_permission = "0600"
}
