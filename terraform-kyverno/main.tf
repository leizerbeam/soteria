# terraform config to setup kyverno on minikube

terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.10.0"
    }
  }
}

provider "kubernetes" {
 config_context_cluster   = "minikube"
}
