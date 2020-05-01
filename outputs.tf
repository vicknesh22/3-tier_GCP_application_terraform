################# Ouptput of VPC #########################################


output "ip_app" {
  value = "${google_compute_instance.app.network_interface.0.network_ip}"
}