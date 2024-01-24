terraform {
  required_version = ">= 1.6"

  required_providers {
	google = ">= 5.10"
  }
}

provider "google" {
  project = "${var.project_id}"
}

resource "google_firestore_database" "database" {
  name                    = "(default)"
  location_id             = "europe-central2"
  type                    = "FIRESTORE_NATIVE"
  delete_protection_state = "DELETE_PROTECTION_ENABLED"
  deletion_policy         = "DELETE"
}

resource "google_storage_bucket" "cloud-function-bucket" {
  name = "cloud-function-bucket-${var.project_id}"
  location = "us-central1"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "cloud-function-archive-AddNewTask" {
  name   = "cloud-function-archive-AddNewTask"
  bucket = google_storage_bucket.cloud-function-bucket.name
  source = "AddNewTask.zip" 
}

resource "google_storage_bucket_object" "cloud-function-archive-deleteOneTask" {
  name   = "cloud-function-archive-deleteOneTask"
  bucket = google_storage_bucket.cloud-function-bucket.name
  source = "deleteOneTask.zip" 
}

resource "google_storage_bucket_object" "cloud-function-archive-editOneTask" {
  name   = "cloud-function-archive-editOneTask"
  bucket = google_storage_bucket.cloud-function-bucket.name
  source = "editOneTask.zip" 
}

resource "google_storage_bucket_object" "cloud-function-archive-emailNotifications" {
  name   = "cloud-function-archive-emailNotifications"
  bucket = google_storage_bucket.cloud-function-bucket.name
  source = "emailNotifications.zip" 
}

resource "google_storage_bucket_object" "cloud-function-archive-getAllTasks" {
  name   = "cloud-function-archive-getAllTasks"
  bucket = google_storage_bucket.cloud-function-bucket.name
  source = "getAllTasks.zip" 
}

resource "google_cloudfunctions2_function" "AddNewTask" {
  name        = "AddNewTask"
  location    = "us-central1"
  description = "Function to add new task"

  build_config {
    runtime = "nodejs20"
    entry_point = "AddNewTask"
    source {
      storage_source {
        bucket = google_storage_bucket.cloud-function-bucket.name
        object = google_storage_bucket_object.cloud-function-archive-AddNewTask.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
  depends_on = [google_firestore_database.database]
}

resource "google_cloudfunctions2_function" "deleteOneTask" {
  name        = "deleteOneTask"
  location    = "us-central1"
  description = "Function to delete task"

  build_config {
    runtime = "nodejs20"
    entry_point = "deleteOneTask"
    source {
      storage_source {
        bucket = google_storage_bucket.cloud-function-bucket.name
        object = google_storage_bucket_object.cloud-function-archive-deleteOneTask.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
  depends_on = [google_firestore_database.database]
}

resource "google_cloudfunctions2_function" "editOneTask" {
  name        = "editOneTask"
  location    = "us-central1"
  description = "Function to edit task"

  build_config {
    runtime = "nodejs20"
    entry_point = "editOneTask"
    source {
      storage_source {
        bucket = google_storage_bucket.cloud-function-bucket.name
        object = google_storage_bucket_object.cloud-function-archive-editOneTask.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
  depends_on = [google_firestore_database.database]
}

resource "google_cloudfunctions2_function" "emailNotifications" {
  name        = "emailNotifications"
  location    = "us-central1"
  description = "Function to send email notifications"

  build_config {
    runtime = "nodejs20"
    entry_point = "emailNotifications"
    source {
      storage_source {
        bucket = google_storage_bucket.cloud-function-bucket.name
        object = google_storage_bucket_object.cloud-function-archive-emailNotifications.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
  depends_on = [google_firestore_database.database]
}

resource "google_cloudfunctions2_function" "getAllTasks" {
  name        = "getAllTasks"
  location    = "us-central1"
  description = "Function to get all tasks"

  build_config {
    runtime = "nodejs20"
    entry_point = "getAllTasks"
    source {
      storage_source {
        bucket = google_storage_bucket.cloud-function-bucket.name
        object = google_storage_bucket_object.cloud-function-archive-getAllTasks.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
  depends_on = [google_firestore_database.database]
}

output "function_uri" {
  value = google_cloudfunctions2_function.emailNotifications.service_config[0].uri
}

resource "google_cloud_scheduler_job" "sendEmail" {
  name         = "sendEmail"
  description  = "Scheduler for sending email with upcoming tasks"
  schedule     = "0 0,8 * * *"
  region = "europe-west1"
  http_target {
    http_method = "POST"
    uri = google_cloudfunctions2_function.emailNotifications.service_config[0].uri
  }
  depends_on = [google_cloudfunctions2_function.emailNotifications]
}