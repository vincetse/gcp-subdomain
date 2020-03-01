################################################################################
# Create both Cloudflare and Google Cloud providers
provider "cloudflare" {
  version   = "~> 2.0"
  api_token = var.cloudflare_api_key
}

provider "google" {
  credentials = var.gcp_credentials
  region      = var.gcp_region
  zone        = var.gcp_zone
  project     = var.gcp_project_id
}

################################################################################
# Create the subdomain and a test record
module "subdomain" {
  source             = "github.com/infrastructure-as-code/terraform-google-cloudflare-subdomain"
  cloudflare_zone_id = var.cloudflare_zone_id
  cloudflare_domain  = var.cloudflare_domain
  sub_domain         = var.sub_domain
  ttl                = 135
}

locals {
  test_hostname = "9c6b61d4.${module.subdomain.dns_name}"
}

resource "google_dns_record_set" "test" {
  name         = local.test_hostname
  type         = "A"
  ttl          = 135
  managed_zone = var.sub_domain
  rrdatas      = [
    "127.0.2.2",
    "127.0.3.3",
  ]
}

resource "null_resource" "wait" {
  # Give the NS record some time to propagate
  provisioner "local-exec" {
    command = "sleep 60"
  }

  depends_on = [
    google_dns_record_set.test,
  ]
}

data "dns_a_record_set" "test" {
  host = local.test_hostname

  depends_on = [
    null_resource.wait,
  ]
}
