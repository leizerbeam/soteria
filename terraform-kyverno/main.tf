# terraform config to setup kyverno on minikube

terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.10.0"
    }

    helm = {
      source = "hashicorp/helm"
      version = "2.5.0"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context_cluster = "minikube"
}

resource "kubernetes_namespace" "kyverno" {
    metadata {
        name = "kyverno"
    }
}

resource "kubernetes_namespace" "kasten-io" {
    metadata {
        name = "kasten-io"
    }
}

provider "helm" {
    kubernetes {
        config_path = "~/.kube/config"
        config_context_cluster = "minikube"
    }
}

resource "helm_release" "k10" {
  name       = "k10"
  repository = "https://charts.kasten.io"
  chart      = "k10"
  namespace  = "kasten-io"
}

  resource "helm_release" "kyverno" {
  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  namespace  = "kyverno"
}

  resource "helm_release" "kyverno-policies" {
  name       = "kyverno-policies"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno-policies"
  namespace  = "kyverno"
}

  provider "kubectl" {
  config_path = "~/.kube/config"
  config_context_cluster = "minikube"
}

resource "kubectl_manifest" "kyvernorbac" {
  yaml_body = file("${path.cwd}/../kyverno/kyvernorbac.yaml")  
}