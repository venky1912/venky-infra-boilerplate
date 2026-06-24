variable "name" { type = string }
variable "kms_keys" { type = any }
variable "security_groups" { type = any }
variable "tags" { type = map(string) }
