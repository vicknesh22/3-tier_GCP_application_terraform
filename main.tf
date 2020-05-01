provider "google" {
  project     = var.project_id_name
  credentials = var.provider_credential
  #version = "2.1.2"
}

##################################----VPC and Subnet Creation-----######################################

module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 2.3"

    project_id   = var.project_id_name
    network_name = var.virtual_name
    routing_mode = "GLOBAL"
    
    subnets = [
        {
            subnet_name           = var.subnet_web
            subnet_ip             = var.ip_subnet_web
            subnet_region         = var.reg_subnet_web
            description           = "This subnet has a frontend of the application"
        },
        {
            subnet_name           = var.subnet_app
            subnet_ip             = var.ip_subnet_app
            subnet_region         = var.reg_subnet_app
            subnet_flow_logs      = "true"
            subnet_flow_logs_interval = "INTERVAL_10_MIN"
            subnet_flow_logs_sampling = 0.7
            description           = "This subnet has a backend DB of the application"
        },

    ]

    secondary_ranges = {
        subnet-01 = [
            {
                range_name    = "subnet-01-secondary-01"
                ip_cidr_range = "192.168.64.0/24"
            },
        ]      
    }
    routes = [
        {
            name                   = "nat-route"
            description            = "route through IGW to access internet"
            destination_range      = "0.0.0.0/0"
            tags                   = "web"
            next_hop_internet      = "true"
            priority               = "300"
        },
    ]   
}

######################################################## NAT #############################################
resource "google_compute_router" "router" {
  name    = var.router_name_web
  region  = var.reg_subnet_app
  network = var.virtual_name

  bgp {
    asn = 64514
  }
  depends_on = [module.vpc.network_name]
}

resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  #nat_ips                            = google_compute_address.address.*.self_link
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = "https://www.googleapis.com/compute/v1/projects/${var.project_id_name}/regions/${var.reg_subnet_app}/subnetworks/${var.subnet_app}"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  depends_on = [module.vpc.subnets]
}


###################################################--------Backend-DB server ---------------##############################################

resource "random_id" "instance_id" {
  byte_length = 8
}
resource "google_compute_instance" "app" {
  name         = "app-${random_id.instance_id.hex}"
  machine_type = var.vmmachine_type
  zone         = "us-west1-b"

  boot_disk {
    initialize_params {
      image = var.image_name
    }
  }
  metadata_startup_script = file("/scripts/mongo_start.sh")

  network_interface {
    network = module.vpc.network_name
    subnetwork = "https://www.googleapis.com/compute/v1/projects/${var.project_id_name}/regions/${var.reg_subnet_app}/subnetworks/${var.subnet_app}"
  }
  // Apply the firewall rule so no external IPs to access this instance
  tags = ["app-server"]
  depends_on = [module.vpc.subnets]
}

resource "google_compute_firewall" "app-server" {
  name    = "default-allow-app-web"
  network = module.vpc.network_name
  

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["10.10.10.0/24"]
  target_tags   = ["app-server"]
}

########################################################----Compute-Instance--WebServer-------#################################################

######################################################-------Template for DBprivate IP #########################################

# Template for initial configuration bash script
data "template_file" "init" {
  template = "${file("/scripts/init.tpl")}"
  #count = 1
  vars = {
    db_internal_ip = "${google_compute_instance.app.network_interface.0.network_ip}"
  }
}

################################# 

resource "google_compute_instance" "web" {
  name         = "web-${random_id.instance_id.hex}"
  machine_type = var.vmmachine_type
  zone         = "us-west1-a"

  boot_disk {
    initialize_params {
      image = var.image_name
    }
  }
  metadata = {
    #server = "web"
    #private IP of the DB server to connect with web server
    
  }
  metadata_startup_script = "${data.template_file.init.rendered}"

  #metadata_startup_script = file("/scripts/start_app.sh")
  network_interface {
    network = module.vpc.network_name
    subnetwork = "https://www.googleapis.com/compute/v1/projects/${var.project_id_name}/regions/${var.reg_subnet_app}/subnetworks/${var.subnet_app}"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }
  // Apply the firewall rule allow external IPs to access this instance
  tags = ["http-server","web"]
  depends_on = [google_compute_instance.app]
}

resource "google_compute_firewall" "http-server" {
  name    = "default-allow-http-web"
  network = module.vpc.network_name
  

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

output "ip_web" {
  value = "${google_compute_instance.web.network_interface.0.access_config.0.nat_ip}"
}