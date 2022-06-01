variable "cidr" {
  description = "CIDR block to use for the VPC"
}

variable "azs" {
  description = "Availability zones to use for the VPC"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnets for the VPC"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnets for the VPC"
  type        = list(string)
}
