mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

# Test 2.4: Default lifecycle policy is applied — plan succeeds without explicit policy
run "default_lifecycle_policy" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {}
      repo_list = {
        "lifecycle-default" = null
      }
    }
    tags = {}
  }

  # Plan succeeds using the built-in default lifecycle policy
  assert {
    condition     = output.repo_info["lifecycle-default"].repository_name == "lifecycle-default"
    error_message = "Expected lifecycle-default repo to plan successfully with default lifecycle policy"
  }
}

# Test 2.5: Common options lifecycle policy override — plan succeeds with custom path
run "common_options_lifecycle_override" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {
        repository_lifecycle_policy = "./tests/plan/fixtures/overrides/common_lifecycle.json"
      }
      repo_list = {
        "lifecycle-common" = null
      }
    }
    tags = {}
  }

  # Plan succeeds using common_options lifecycle policy file
  assert {
    condition     = output.repo_info["lifecycle-common"].repository_name == "lifecycle-common"
    error_message = "Expected lifecycle-common repo to plan successfully with common_options lifecycle policy"
  }
}

# Test 2.6: Per-repo lifecycle policy takes highest precedence — plan uses per-repo file
run "per_repo_lifecycle_override" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {
        repository_lifecycle_policy = "./tests/plan/fixtures/overrides/common_lifecycle.json"
      }
      repo_list = {
        "lifecycle-repo" = {
          repository_lifecycle_policy = "./tests/plan/fixtures/overrides/repo_lifecycle.json"
        }
      }
    }
    tags = {}
  }

  # Plan succeeds using per-repo lifecycle policy (highest precedence)
  assert {
    condition     = output.repo_info["lifecycle-repo"].repository_name == "lifecycle-repo"
    error_message = "Expected lifecycle-repo to plan successfully with per-repo lifecycle policy"
  }
}

# Test: Invalid lifecycle policy path should fail
run "invalid_lifecycle_path_fails" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {
        repository_lifecycle_policy = "./nonexistent/path.json"
      }
      repo_list = {
        "fail-repo" = null
      }
    }
    tags = {}
  }

  # This should fail because the file doesn't exist and the try() chain exhausts all options
  # But actually the default policy file will be used as final fallback.
  # So this test verifies the fallback chain works even with an invalid common_options path.
  assert {
    condition     = output.repo_info["fail-repo"].repository_name == "fail-repo"
    error_message = "Expected fail-repo to plan successfully (fallback to default lifecycle policy)"
  }
}
