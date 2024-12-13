# Google Cloud Load Balancer Module

This module creates a Google Cloud Load Balancer that supports both backend buckets (for static content) and backend services (for compute resources like Cloud Run). It provides flexibility in routing traffic based on hosts and paths while supporting SSL and CDN configurations.

## Features

- Support for both backend buckets and backend services
- Managed SSL certificates
- HTTP to HTTPS redirect
- CDN configuration
- Flexible URL mapping with host and path-based routing
- Health checks for backend services

## Usage

### Basic usage with a backend bucket for static content:

```hcl
module "load_balancer" {
  source  = "./modules/load-balancer"
  
  project = "my-project-id"
  name    = "my-lb"
  
  ssl     = true
  domains = ["example.com"]
  
  backend_buckets = {
    static = {
      bucket_name = "my-static-bucket"
      enable_cdn  = true
      cdn_policy = {
        cache_mode    = "CACHE_ALL_STATIC"
        default_ttl   = 3600
        client_ttl    = 3600
        max_ttl       = 86400
      }
    }
  }
  
  url_map_config = {
    default_service = "static"
    host_rules = [{
      hosts        = ["example.com"]
      path_matcher = "main"
    }]
    path_matchers = [{
      name            = "main"
      default_service = "static"
    }]
  }
}
```

### Adding a Cloud Run backend service:

```hcl
module "load_balancer" {
  # ... previous configuration ...
  
  backend_services = {
    api = {
      protocol    = "HTTPS"
      port        = 443
      port_name   = "http"
      enable_cdn  = false
      backend_type = "serverless_neg"
      backends = [{
        group = google_compute_region_network_endpoint_group.cloudrun_neg.id
      }]
      health_check = {
        port         = 443
        request_path = "/health"
      }
    }
  }
  
  url_map_config = {
    default_service = "static"
    host_rules = [{
      hosts        = ["example.com"]
      path_matcher = "main"
    }]
    path_matchers = [{
      name            = "main"
      default_service = "static"
      path_rules = [{
        paths   = ["/api/*"]
        service = "api"
      }]
    }]
  }
}
```

## Inputs

| Name    | Description                                            | Type         | Required |
| ------- | ------------------------------------------------------ | ------------ | -------- |
| project | The project ID where the load balancer will be created | string       | yes      |
| name    | Name prefix for all load balancer resources            | string       | yes      |
| ssl     | Enable HTTPS and create managed SSL certificates       | bool         | no       |
| domains | List of domains for the SSL certificate                | list(string) | no       |