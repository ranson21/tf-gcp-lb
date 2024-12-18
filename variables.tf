variable "project" {
  description = "The project ID where the load balancer will be created"
  type        = string
}

variable "name" {
  description = "Name prefix for all load balancer resources"
  type        = string
}

variable "ssl" {
  description = "Enable HTTPS and create managed SSL certificates"
  type        = bool
  default     = true
}

variable "domains" {
  description = "List of domains for the SSL certificate. Required if ssl is true"
  type        = list(string)
  default     = []
}

variable "enable_http_to_https_redirect" {
  description = "Enable HTTP to HTTPS redirect"
  type        = bool
  default     = true
}

variable "backend_buckets" {
  description = "Map of backend buckets configurations"
  type = map(object({
    bucket_name             = string
    enable_cdn              = bool
    description             = optional(string)
    custom_response_headers = optional(list(string))
    edge_security_policy    = optional(string)
    cdn_policy = optional(object({
      cache_mode        = optional(string)
      client_ttl        = optional(number)
      default_ttl       = optional(number)
      max_ttl           = optional(number)
      negative_caching  = optional(bool)
      serve_while_stale = optional(number)
    }))
  }))
  default = {}
}

variable "backend_services" {
  description = "Map of backend service configurations"
  type = map(object({
    protocol     = string
    port         = number
    port_name    = string
    enable_cdn   = optional(bool)
    description  = optional(string)
    backend_type = string # Can be "instance_group", "serverless_neg", etc.
    backends = list(object({
      group           = string
      balancing_mode  = optional(string)
      capacity_scaler = optional(number)
    }))
    health_check = optional(object({
      port               = optional(number)
      request_path       = optional(number)
      check_interval_sec = optional(number)
      timeout_sec        = optional(number)
    }))
    cdn_policy = optional(object({
      cache_mode        = optional(string)
      client_ttl        = optional(number)
      default_ttl       = optional(number)
      max_ttl           = optional(number)
      negative_caching  = optional(bool)
      serve_while_stale = optional(number)
    }))
  }))
  default = {}
}

variable "url_map_config" {
  description = "Configuration for URL map path matchers and host rules"
  type = object({
    default_service = string
    host_rules = list(object({
      hosts        = list(string)
      path_matcher = string
    }))
    path_matchers = list(object({
      name            = string
      default_service = string
      path_rules = optional(list(object({
        paths   = list(string)
        service = string
      })))
    }))
  })
}
