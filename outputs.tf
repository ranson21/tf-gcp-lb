output "external_ip" {
  description = "The external IP address of the load balancer"
  value       = google_compute_global_address.default.address
}

output "backend_buckets" {
  description = "Map of created backend buckets and their details"
  value = {
    for k, v in google_compute_backend_bucket.buckets : k => {
      name        = v.name
      bucket_name = v.bucket_name
      self_link   = v.self_link
    }
  }
}

output "backend_services" {
  description = "Map of created backend services and their details"
  value = {
    for k, v in google_compute_backend_service.services : k => {
      name      = v.name
      self_link = v.self_link
      protocol  = v.protocol
      port_name = v.port_name
    }
  }
}

output "url_map" {
  description = "The created URL map resource"
  value = {
    name      = google_compute_url_map.default.name
    self_link = google_compute_url_map.default.self_link
  }
}

output "https_proxy" {
  description = "The HTTPS proxy resource (if SSL is enabled)"
  value = var.ssl ? {
    name      = google_compute_target_https_proxy.default[0].name
    self_link = google_compute_target_https_proxy.default[0].self_link
  } : null
}

output "certificate" {
  description = "The managed SSL certificate resource (if SSL is enabled)"
  value = var.ssl ? {
    name      = google_compute_managed_ssl_certificate.default[0].name
    domains   = google_compute_managed_ssl_certificate.default[0].managed[0].domains
    self_link = google_compute_managed_ssl_certificate.default[0].self_link
  } : null
}
