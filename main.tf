# Create global IP address
resource "google_compute_global_address" "default" {
  project = var.project
  name    = "${var.name}-address"
}

# Create backend buckets
resource "google_compute_backend_bucket" "buckets" {
  for_each = var.backend_buckets

  project     = var.project
  name        = "${var.name}-bucket-${each.key}"
  bucket_name = each.value.bucket_name
  enable_cdn  = each.value.enable_cdn
  description = each.value.description

  dynamic "cdn_policy" {
    for_each = each.value.cdn_policy != null ? [each.value.cdn_policy] : []
    content {
      cache_mode        = cdn_policy.value.cache_mode
      client_ttl        = cdn_policy.value.client_ttl
      default_ttl       = cdn_policy.value.default_ttl
      max_ttl           = cdn_policy.value.max_ttl
      negative_caching  = cdn_policy.value.negative_caching
      serve_while_stale = cdn_policy.value.serve_while_stale
    }
  }
}

# Create health checks for backend services
resource "google_compute_health_check" "default" {
  for_each = var.backend_services

  project = var.project
  name    = "${var.name}-hc-${each.key}"

  http_health_check {
    port         = each.value.health_check.port
    request_path = each.value.health_check.request_path

    check_interval_sec = each.value.health_check.check_interval_sec
    timeout_sec        = each.value.health_check.timeout_sec
  }
}

# Create backend services
resource "google_compute_backend_service" "services" {
  for_each = var.backend_services

  project     = var.project
  name        = "${var.name}-service-${each.key}"
  protocol    = each.value.protocol
  port_name   = each.value.port_name
  enable_cdn  = each.value.enable_cdn
  description = each.value.description

  dynamic "backend" {
    for_each = each.value.backends
    content {
      group           = backend.value.group
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
    }
  }

  health_checks = [google_compute_health_check.default[each.key].id]

  dynamic "cdn_policy" {
    for_each = each.value.cdn_policy != null ? [each.value.cdn_policy] : []
    content {
      cache_mode        = cdn_policy.value.cache_mode
      client_ttl        = cdn_policy.value.client_ttl
      default_ttl       = cdn_policy.value.default_ttl
      max_ttl           = cdn_policy.value.max_ttl
      negative_caching  = cdn_policy.value.negative_caching
      serve_while_stale = cdn_policy.value.serve_while_stale
    }
  }
}

# Create SSL certificate if SSL is enabled
resource "google_compute_managed_ssl_certificate" "default" {
  count = var.ssl ? 1 : 0

  project = var.project
  name    = "${var.name}-cert"

  managed {
    domains = var.domains
  }
}

# Create URL map
resource "google_compute_url_map" "default" {
  project = var.project
  name    = "${var.name}-url-map"

  # Look up the default service in either backend buckets or services
  default_service = (
    contains(keys(var.backend_buckets), var.url_map_config.default_service)
    ? google_compute_backend_bucket.buckets[var.url_map_config.default_service].self_link
    : google_compute_backend_service.services[var.url_map_config.default_service].self_link
  )

  dynamic "host_rule" {
    for_each = var.url_map_config.host_rules
    content {
      hosts        = host_rule.value.hosts
      path_matcher = host_rule.value.path_matcher
    }
  }

  dynamic "path_matcher" {
    for_each = var.url_map_config.path_matchers
    content {
      name = path_matcher.value.name
      default_service = (
        contains(keys(var.backend_buckets), path_matcher.value.default_service)
        ? google_compute_backend_bucket.buckets[path_matcher.value.default_service].self_link
        : google_compute_backend_service.services[path_matcher.value.default_service].self_link
      )

      dynamic "path_rule" {
        for_each = path_matcher.value.path_rules != null ? path_matcher.value.path_rules : []
        content {
          paths = path_rule.value.paths
          service = (
            contains(keys(var.backend_buckets), path_rule.value.service)
            ? google_compute_backend_bucket.buckets[path_rule.value.service].self_link
            : google_compute_backend_service.services[path_rule.value.service].self_link
          )
        }
      }
    }
  }
}

# Create HTTPS proxy if SSL is enabled
resource "google_compute_target_https_proxy" "default" {
  count = var.ssl ? 1 : 0

  project = var.project
  name    = "${var.name}-https-proxy"
  url_map = google_compute_url_map.default.self_link

  ssl_certificates = [google_compute_managed_ssl_certificate.default[0].self_link]
}

# Create HTTP proxy
resource "google_compute_target_http_proxy" "default" {
  project = var.project
  name    = "${var.name}-http-proxy"
  url_map = (
    var.enable_http_to_https_redirect
    ? google_compute_url_map.http_redirect[0].self_link
    : google_compute_url_map.default.self_link
  )
}

# Create HTTPS forwarding rule if SSL is enabled
resource "google_compute_global_forwarding_rule" "https" {
  count = var.ssl ? 1 : 0

  project    = var.project
  name       = "${var.name}-https-rule"
  target     = google_compute_target_https_proxy.default[0].self_link
  ip_address = google_compute_global_address.default.address
  port_range = "443"
}

# Create HTTP forwarding rule
resource "google_compute_global_forwarding_rule" "http" {
  project    = var.project
  name       = "${var.name}-http-rule"
  target     = google_compute_target_http_proxy.default.self_link
  ip_address = google_compute_global_address.default.address
  port_range = "80"
}

# Create URL map for HTTP to HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  count = var.enable_http_to_https_redirect ? 1 : 0

  project = var.project
  name    = "${var.name}-http-redirect"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}
