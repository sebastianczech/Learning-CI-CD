terraform {
  backend "remote" {
    organization = "sebastianczech"

    workspaces {
      name = "Learning-Terraform"
    }
  }
}

