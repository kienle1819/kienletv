resource "random_password" "user_password" {
  length           = 24
  special          = true
  min_special      = 2
  override_special = "!#$%^&*()-_=+[]{}<>:?"
  keepers = {
    password_version = var.password_version
  }
}

resource "mysql_database" "user_db" {
  provider = mysql.local
  name = var.database_name
}

resource "mysql_user" "user_id" {
  provider = mysql.local
  user = var.database_username
  plaintext_password = random_password.user_password.result
  host = "%"
  tls_option = "NONE"
}

resource "mysql_grant" "user_id" {
  provider = mysql.local
  user = var.database_username
  host = "%"
  database = var.database_name
  privileges = ["SELECT", "UPDATE"]
  depends_on = [
    mysql_user.user_id
  ]
}