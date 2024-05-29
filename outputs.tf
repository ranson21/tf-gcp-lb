output "lb_ip" {
  value = google_compute_global_address.default.address
}

output "ssl_cert_id" {
  value = google_compute_managed_ssl_certificate.default.id
}
