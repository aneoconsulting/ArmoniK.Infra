locals {
  database_init_script = <<EOF
    db = db.getSiblingDB("database");
    db.createCollection("sample")
    db.sample.insertOne({test:1})
    db.createUser(
    {
        user: "${random_string.mongodb_application_user.result}",
        pwd: "${random_password.mongodb_application_password.result}",
        roles: [ {role: "readWrite", db: "database" }, { role: "dbAdmin", db: "database" }]
    }
    );
    db.sample.drop()
    EOF
}

resource "kubernetes_config_map" "database_init_script" {
  metadata {
    name      = "database-init-script"
    namespace = var.namespace
  }
  data = {
    "initDatabase.js" = local.database_init_script
  }
}

resource "kubernetes_config_map" "mongodb_extra_env_vars" {
  metadata {
    name = "mongodb-extra-env-vars"
    namespace = var.namespace
  }
  data = {
    MONGO_USERNAME = random_string.mongodb_application_user.result
    MONGO_PASSWORD = random_password.mongodb_application_password.result
  }
}

resource "local_file" "init_script_file" {
  content  = local.database_init_script
  filename = "${path.root}/generated/configmaps/database_init_script.js"
}
