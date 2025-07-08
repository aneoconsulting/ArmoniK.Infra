locals {
  database_init_script = <<EOF
    // Create users in admin database
    db = db.getSiblingDB("admin");
    
    // Create monitoring user in admin database
    db.createUser(
    {
        user: "${random_string.mongodb_monitoring_user.result}",
        pwd: "${random_password.mongodb_monitoring_password.result}",
        roles: [ 
          { role: "read", db: "local" }, 
          { role: "read", db: "database" },
          { role: "clusterMonitor", db: "admin" },
          { role: "read", db: "config" }
        ]
    }
    );
    
    db = db.getSiblingDB("${var.mongodb.database_name}");
    db.createCollection("sample")
    db.sample.insertOne({test:1})
    db.createUser(
    {
        user: "${random_string.mongodb_application_user.result}",
        pwd: "${random_password.mongodb_application_password.result}",
        roles: [ 
          { role: "readWrite", db: "${var.mongodb.database_name}" }, 
          { role: "dbAdmin", db: "${var.mongodb.database_name}" }
        ]
    }
    );
    db.sample.drop()
    db.adminCommand(
    {
      enableSharding: "${var.mongodb.database_name}"
    }
    );
    EOF
}

resource "kubernetes_secret" "database_init_script" {
  metadata {
    name      = "${var.name}-database-init-script"
    namespace = var.namespace
  }
  data = {
    "initDatabase.js" = local.database_init_script
  }
}

resource "local_sensitive_file" "init_script_file" {
  content  = local.database_init_script
  filename = "${path.root}/generated/${var.name}/configmaps/database_init_script.js"
}