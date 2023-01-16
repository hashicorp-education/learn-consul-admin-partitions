output "howto_connect" {
  value = <<EOF
  To access Consul from your local client run:

  export CONSUL_HTTP_ADDR="${hcp_consul_cluster.main.consul_public_endpoint_url}"
  export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_root_token)
  
  You can access your provisioned eks clusters by using the following kubeconfigs:

  export KUBECONFIG=$(terraform output -raw kubeconfig_filename-a)
  export KUBECONFIG=$(terraform output -raw kubeconfig_filename-b)
  export KUBECONFIG=$(terraform output -raw kubeconfig_filename-c)

  Example next steps for eks_cluster-a :

  export CONSUL_HTTP_TOKEN=$(terraform output -raw hcp_consul_root_token)
  kubectl --context eks_cluster-a create namespace consul
  kubectl --context eks_cluster-a create secret generic "consul-bootstrap-token" --from-literal="token=$\{CONSUL_HTTP_TOKEN\}" --namespace consul
  kubectl --context eks_cluster-a create secret generic "consul-ca-cert" --from-file='tls.crt=./hcp_ca.pem'  --namespace consul
  consul-k8s install -context=eks_cluster-a -config-file=consul-values-a.yaml
  EOF
}


