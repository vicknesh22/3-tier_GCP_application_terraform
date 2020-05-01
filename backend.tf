terraform {
    backend "gcs" {
    bucket      = "terrafstate"
    prefix      = "terraform11.1/state"
    credentials = "C:\\Users\\vrethinavelu\\Downloads\\service_account.json"
  }
}

