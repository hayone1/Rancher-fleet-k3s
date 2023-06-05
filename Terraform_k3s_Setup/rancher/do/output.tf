
output "rancher_server_url" {
  value = module.rancher_common.rancher_url
}

output "rancher_node_ip" {
  value = digitalocean_droplet.rancher_server.ipv4_address
}

output "workload_1_node_ip" {
  value = digitalocean_droplet.cluster_node1.ipv4_address
}

output "workload_2_node_ip" {
  value = digitalocean_droplet.cluster_node2.ipv4_address
}
