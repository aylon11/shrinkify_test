variable "project_id" {
  type = string
}

variable "project_number" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "location" {
  type    = string
  default = "US"
}

variable "service_name" {
  type    = string
  default = "shrinkify"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_container_registry_image" "shrinkify_image" {
  name = "gcr.io/${var.project_id}/${var.service_name}:latest"
}

resource "google_cloud_run_service" "shrinkify_service" {
  name     = "${var.service_name}-service"
  location = var.region
  template {
    spec {
      containers {
        image = data.google_container_registry_image.shrinkify_image.name
        env {
          name = "PROJECT_NAME"
          value = var.project_id
        }
        env {
          name = "PROJECT_NUMBER"
          value = var.project_number
        }
      }
    }
    metadata {
      annotations = {
        "run.googleapis.com/ingress" = "all"
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}
data "google_iam_policy" "public_access" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}
resource "google_cloud_run_service_iam_policy" "public_access" {
  location    = google_cloud_run_service.shrinkify_service.location
  project     = google_cloud_run_service.shrinkify_service.project
  service     = google_cloud_run_service.shrinkify_service.name
  policy_data = data.google_iam_policy.shrinkify_service.policy_data
}