terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name = "Terraform-POC"
    storage_account_name = "terraformpocinspyre2test"
    container_name = "state"
    key = "terraform.state"
  }
}

# Resource Group
resource "azurerm_resource_group" "case2" {
  name = "Case2"
  location = "West Europe"
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "case2_cluster" {
  name = "case2-aks-cluster"
  location = azurerm_resource_group.case2.location
  resource_group_name = azurerm_resource_group.case2.name
  dns_prefix = "casecluster"
  
  agent_pool_profile {
      name = "agentpool"
      count = 1
      vm_size = "Standard_D2_v2"
  }

  # Secret
  service_principal {
    client_id = "clientID"
    client_secret = "secret"
  } 
}

# Deploy the containerized backend to AKS
resource "kubernetes_namespace" "backend" {
  metadata {
    name = "backend"
  }
}

# Kubernetes Deployment
resource "kubernetes_deployment" "backend_deploy" {
  metadata {
    name = "backend-deploy"
    namespace = kubernetes_namespace.backend.metadata[0].name
    labels = {
      "app" = "backend"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
          app = "backend"
      }
    }
    template {
      metadata {
          labels = {
              app = "backend"
          }
      }
      spec {
          container {
              name = "backend-container"
              image = "the_backend_image"
              ports {
                  container_port = 8080
              }
              env {
                  name = "DATABASE"
                  value = "The DB connection string"
              }
              # You can add more container spec here if it needs
          }
      }
    }
  }
}

# Backend Service
resource "kubernetes_service" "backend_service" {
  metadata {
    name = "backend-service"
    namespace = kubernetes_namespace.backend.metadata[0].name
  }

  spec {
    selector = {
      "app" = "backend"
    }
    port {
      name = "http"
      port = 80
      target_port = 8080
    }
  }
}

# UI deploy
resource "kubernetes_namespace" "ui" {
  metadata {
    name = "ui"
  }
}

# UI Deployment
resource "kubernetes_deployment" "ui_deployment" {
  metadata {
    name = "ui-deployment"
    namespace = kubernetes_namespace.ui.metadata[0].name
    labels = {
      "app" = "ui"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app" = "ui"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "ui"
        }
      }
      spec {
        container {
          name = "ui-container"
          image = "Image that we want to use"
          ports {
            container_port = 80
          }
        }
      }
    }
  }
}

# UI Service
resource "kubernetes_service" "ui_service" {
  metadata {
    name = "ui-service"
    namespace = kubernetes_namespace.ui.metadata[0].name
  }
  spec {
    selector = {
      "app" = "ui"
    }
    port {
      name = "http"
      port = 80
      target_port = 80
    }
  }
}