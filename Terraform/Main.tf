#
# Main.tf
#
# Manages this repository's GitHub settings, including merge options and the rulesets that
# protect main and release with the required CI checks. Run plans and applies from this
# folder with GITHUB_TOKEN set, for example
# "GITHUB_TOKEN=$(gh auth token) terraform plan".
#

terraform {
    required_version = ">= 1.5"

    # State lives in HCP Terraform. The organization comes from the TF_CLOUD_ORGANIZATION
    # environment variable, and plans run locally.
    cloud {
        workspaces {
            name = "assetfile"
        }
    }

    required_providers {
        github = {
            source = "integrations/github"
            version = "~> 6.0"
        }
    }
}

provider "github" {
    # Authenticates via the GITHUB_TOKEN environment variable.
    owner = "horsenuggets"
}

locals {
    repo_name = "assetfile"

    # Must match the job `name:` fields of every workflow that runs on PRs to main.
    main_checks = [
        "Check .luaurc format",
        "Check changelog format",
        "Check file headers",
        "Check for tabs",
        "Check formatting",
        "Check JSON format",
        "Check rokit.toml format",
        "Check version match",
        "Check wally.toml format",
        "Run tests",
        "Static analysis",
        "Validate branch name"
    ]

    # Must match the job `name:` fields of every workflow that runs on PRs to release.
    release_checks = [
        "Build test linux-aarch64",
        "Build test linux-x86_64",
        "Build test macos-aarch64",
        "Build test macos-x86_64",
        "Build test windows-aarch64",
        "Build test windows-x86_64",
        "Check formatting",
        "Check JSON format",
        "Run tests",
        "Static analysis",
        "Validate PR title",
        "Validate version",
        "Verify diff matches main"
    ]
}

# Adopt the existing repository instead of trying to create it. The id must be a literal
# string on Terraform 1.5, so keep it in sync with local.repo_name.
import {
    to = github_repository.repo
    id = "assetfile"
}

resource "github_repository" "repo" {
    name = local.repo_name

    has_issues = true
    has_projects = false
    has_wiki = false

    allow_squash_merge = true
    allow_merge_commit = false
    allow_rebase_merge = false

    squash_merge_commit_title = "PR_TITLE"
    squash_merge_commit_message = "PR_BODY"

    delete_branch_on_merge = true

    lifecycle {
        # Destroying this resource would delete the repository on GitHub.
        prevent_destroy = true

        # Managed in the GitHub UI, so applies don't overwrite them.
        ignore_changes = [allow_auto_merge, description, topics, visibility]
    }
}

resource "github_repository_ruleset" "main" {
    name = "main"
    repository = github_repository.repo.name
    target = "branch"
    enforcement = "active"

    conditions {
        ref_name {
            include = ["~DEFAULT_BRANCH"]
            exclude = []
        }
    }

    rules {
        non_fast_forward = true
        deletion = true

        pull_request {
            required_approving_review_count = 0
            dismiss_stale_reviews_on_push = true
        }

        required_status_checks {
            strict_required_status_checks_policy = true

            dynamic "required_check" {
                for_each = local.main_checks
                content {
                    context = required_check.value
                    integration_id = 0
                }
            }
        }
    }
}

resource "github_repository_ruleset" "release" {
    name = "release"
    repository = github_repository.repo.name
    target = "branch"
    enforcement = "active"

    conditions {
        ref_name {
            include = ["refs/heads/release"]
            exclude = []
        }
    }

    rules {
        non_fast_forward = true
        deletion = true

        pull_request {
            required_approving_review_count = 0
            dismiss_stale_reviews_on_push = true
        }

        required_status_checks {
            strict_required_status_checks_policy = true

            dynamic "required_check" {
                for_each = local.release_checks
                content {
                    context = required_check.value
                    integration_id = 0
                }
            }
        }
    }
}
