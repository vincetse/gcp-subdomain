output "test_host_ip" {
  value = data.dns_a_record_set.test.addrs
}
