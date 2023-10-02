output "user" {
  value = mysql_user.user_id.user
}

output "password" {
  sensitive = true
  value = random_password.user_password.result
}