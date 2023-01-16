data "aws_eks_cluster" "cluster-c" {
  name  = module.eks-c.cluster_id
}

data "aws_eks_cluster_auth" "cluster-c" {
  name  = module.eks-c.cluster_id
}

module "eks-c" {
  source                 = "terraform-aws-modules/eks/aws"
  version                = "17.24.0"
  kubeconfig_api_version = "client.authentication.k8s.io/v1beta1"

  cluster_name    = "cluster-c"
  cluster_version = "1.21"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  manage_aws_auth = false

  node_groups = {
    application = {
      name_prefix    = "hashicups"
      instance_types = ["t3a.medium"]

      desired_capacity = 3
      max_capacity     = 3
      min_capacity     = 3
    }
  }
}

output "kubeconfig_filename-c" {
  value = abspath(module.eks-c.kubeconfig_filename)
}

resource "local_sensitive_file" "consul-values-c" {
  filename = "${path.module}/yamls/consul-values-c.yaml"
  content  = <<EOT
global:
  name: consul
  enabled: false
  datacenter: ${hcp_consul_cluster.main.datacenter}
  image: "hashicorp/consul-enterprise:${hcp_consul_cluster.main.consul_version}-ent"
  adminPartitions:
    enabled: true
    name: part2
  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: consul-bootstrap-token
      secretKey: token
  tls:
    enabled: true
    caCert:
      secretName: consul-ca-cert
      secretKey: tls.crt
  enableConsulNamespaces: true
externalServers:
  enabled: true
  hosts: ["${replace(hcp_consul_cluster.main.consul_private_endpoint_url,"/(https://)|(/)/","")}"]
  httpsPort: 443
  useSystemRoots: true
  k8sAuthMethodHost: ${module.eks-c.cluster_endpoint}
server:
  enabled: false
connectInject:
  enabled: true
ingressGateways:
  enabled: true
  defaults:
    replicas: 1
  gateways:
    - name: ingress-gateway
      service:
        type: LoadBalancer
        ports:
          - port: 8080
EOT
}
