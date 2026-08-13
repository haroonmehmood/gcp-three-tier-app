data "google_project" "project" {}

resource "google_compute_instance" "default" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.instance_image
    }
  }

  network_interface {
    network = var.network_name
    subnetwork = var.subnetwork_name
    access_config {}
  }

  metadata_startup_script = file("./modules/gce/apache2.sh")

  service_account {
    email  = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}
