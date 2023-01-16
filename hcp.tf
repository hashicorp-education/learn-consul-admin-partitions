# The HVN created in HCP
resource "hcp_hvn" "main" {
  hvn_id         = local.hvn_id
  cloud_provider = "aws"
  region         = local.hvn_region
  cidr_block     = "172.25.32.0/20"
}

module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "~> 0.7.0"

  hvn             = hcp_hvn.main
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnets
  route_table_ids = module.vpc.public_route_table_ids
}

resource "hcp_consul_cluster" "main" {
  cluster_id         = local.cluster_id
  hvn_id             = hcp_hvn.main.hvn_id
  public_endpoint    = true
  tier               = "development"
  min_consul_version = "v1.14.0"
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.main.id
}

output "hcp_consul_root_token" {
  value     = hcp_consul_cluster_root_token.token.secret_id
  sensitive = true
}

output "hcp_consul_url" {
  value = hcp_consul_cluster.main.public_endpoint ? (
    hcp_consul_cluster.main.consul_public_endpoint_url
    ) : (
    hcp_consul_cluster.main.consul_private_endpoint_url
  )
}

output "hcp_consul_datacenter" {
  sensitive = true
  value = hcp_consul_cluster.main.datacenter
}

output "hcp_consul_endpoint" {
  sensitive = true
  value = replace(hcp_consul_cluster.main.consul_private_endpoint_url,"/(https://)|(/)/","")
}

output "hcp_consul_version" {
  sensitive = true
  value = hcp_consul_cluster.main.consul_version
}

resource "local_sensitive_file" "hcp_ca" {
  filename = "${path.module}/hcp_ca.pem"
  content = base64decode(hcp_consul_cluster.main.consul_ca_file)
}