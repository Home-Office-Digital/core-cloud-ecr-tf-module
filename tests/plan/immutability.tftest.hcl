mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

# Test 2.12: Default immutability settings — plan succeeds with IMMUTABLE_WITH_EXCLUSION defaults
run "default_immutability" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {}
      repo_list = {
        "immutable-repo" = null
      }
    }
    tags = {}
  }

  # Plan succeeds with default IMMUTABLE_WITH_EXCLUSION config
  assert {
    condition     = output.repo_info["immutable-repo"].repository_name == "immutable-repo"
    error_message = "Expected immutable-repo to plan successfully with default immutability settings"
  }
}

# Test: Custom immutability override via common_options
run "custom_immutability_override" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {
        repository_image_tag_mutability = "MUTABLE"
      }
      repo_list = {
        "mutable-repo" = null
      }
    }
    tags = {}
  }

  # Plan succeeds with MUTABLE override
  assert {
    condition     = output.repo_info["mutable-repo"].repository_name == "mutable-repo"
    error_message = "Expected mutable-repo to plan successfully with MUTABLE override"
  }
}
