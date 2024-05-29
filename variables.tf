variable "domain" {}
variable "project" {}
variable "name" {}

variable "url_map" {
  description = "URL Map to forward traffice on the load balancer"
}

variable "network" {
  description = "VPC Network for the load balancer"
}

variable "create_http_forward" {
  description = "Forward HTTP traffic to HTTPS"
  default     = true
}

variable "source_ranges" {
  default = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
}
