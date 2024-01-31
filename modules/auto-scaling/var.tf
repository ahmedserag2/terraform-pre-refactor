variable "env" {
  default = "dev"
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "public_sub_ids" {
  type = list(string)
}