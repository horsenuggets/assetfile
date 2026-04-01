terraform {
  required_version = ">= 1.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = "horsenuggets"
}

module "repo" {
  source     = "../Submodules/luau-cicd/Terraform/Modules/CommandlineCli"
  repository = "assetfile"

  extra_release_checks = [
    "Build test linux-x86_64",
    "Build test linux-aarch64",
    "Build test macos-x86_64",
    "Build test macos-aarch64",
    "Build test windows-x86_64",
    "Build test windows-aarch64",
  ]
}
