terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name = "Terraform-POC"
    storage_account_name = "terraformpocinspyretest"
    container_name = "state"
    key = "terraform.state"
  }
}

provider "azurerm" {
  features {}
}

#Resource Group
resource "azurerm_resource_group" "Case1" {
  name = "Case1"
  location = "West Europe"
}

# Create AKS Cluster
resource "azurerm_kubernetes_cluster" "inspyre" {
  name = "Inspyre"
  location = azurerm_resource_group.Case1.location
  resource_group_name = azurerm_resource_group.Case1.name

  # DNS prefix for AKS will be inspyre-cluster-dns.weseurope.cloudapp.azure.com
  dns_prefix = "inspyre-cluster-dns"

  # Specify the admin profile to the AKS
  linux_profile {
    admin_username = "inspyre"

    ssh_key {
        key_data = "ssh-rsa Need to generate it"
    }
  }

  # Agent configuration
  agent_pool_profile {
    name = "aks-inspyre"
    count = 1
    vm_size = "Standard_DS2_v2"
    os_type = "Linux"
    vnet_subnet_id = "Insert the subnet"
    availability_zones = ["Add the availability zone"]
  }

  # Secret
  service_principal {
    client_id =  "client id"
    client_secret = "client secret"
  }

  depends_on = [
    azurerm_resource_group.Case1
  ]
}

# Kubernetes namespace
resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "nginx"
  }
}

# Nginx Helm Repo
resource "helm_repository" "nginx" {
  name = "nginx-stable"
  url = "https://helm.nginx.com/stable"
}

# Nginx Helm Chart
resource "helm_release" "nginx" {
  name = "nginx-ingress"
  repository = "helm_repository.nginx.metadata[0].name"
  chart = "nginx-ingress"
  namespace = kubernetes_namespace.nginx.metadata[0].name

  # Set controller.service.type to Internal => Internal load balancer
  set {
    name = "controller.service.type"
    value = "Internal"
  }

  depends_on = [
    kubernetes_namespace.nginx
  ]
}