
resource "google_compute_global_address" "default" {
  project = var.project
  name    = "${var.name}-address"
}

resource "google_compute_managed_ssl_certificate" "default" {
  name = "${var.name}-cert"

  managed {
    domains = [var.domain]
  }
}

resource "google_compute_global_forwarding_rule" "http" {
  name       = "${var.name}-http"
  project    = var.project
  count      = var.create_http_forward ? 1 : 0
  target     = google_compute_target_http_proxy.default.self_link
  ip_address = google_compute_global_address.default.address
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "https" {
  project    = var.project
  name       = "${var.name}-https"
  target     = google_compute_target_https_proxy.default.self_link
  ip_address = google_compute_global_address.default.address
  port_range = "443"
}

# HTTP proxy when http forwarding is true
resource "google_compute_target_http_proxy" "default" {
  project = var.project
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.https_redirect.self_link
}

# HTTPS proxy when ssl is true
resource "google_compute_target_https_proxy" "default" {
  project = var.project
  name    = "${var.name}-https-proxy"
  url_map = var.url_map

  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

resource "google_compute_url_map" "https_redirect" {
  project = var.project
  name    = "${var.name}-https-redirect"
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_dns_record_set" "set" {
  name         = "${var.domain}."
  type         = "A"
  ttl          = 3600
  managed_zone = var.network
  rrdatas      = [google_compute_global_address.default.address]
}
