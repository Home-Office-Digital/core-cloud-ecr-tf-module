mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

# Test 2.1: Repository naming without prefix
run "no_prefix_naming" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {}
      repo_list = {
        "app-one" = null
        "app-two" = null
      }
    }
    tags = {}
  }

  assert {
    condition     = output.repo_info["app-one"].repository_name == "app-one"
    error_message = "Expected repository name 'app-one' when no prefix is set, got '${output.repo_info["app-one"].repository_name}'"
  }

  assert {
    condition     = output.repo_info["app-two"].repository_name == "app-two"
    error_message = "Expected repository name 'app-two' when no prefix is set, got '${output.repo_info["app-two"].repository_name}'"
  }
}

# Test 2.2: Repository naming with prefix
run "with_prefix_naming" {
  command = plan

  variables {
    ecr_prefix = "my-tenant"
    ecr_config = {
      common_options = {}
      repo_list = {
        "service-a" = null
      }
    }
    tags = {}
  }

  assert {
    condition     = output.repo_info["service-a"].repository_name == "my-tenant/service-a"
    error_message = "Expected repository name 'my-tenant/service-a' when prefix is set, got '${output.repo_info["service-a"].repository_name}'"
  }
}

# Test 2.3: Prefix and repo name trimming
run "prefix_and_name_trimming" {
  command = plan

  variables {
    ecr_prefix = "-padded-"
    ecr_config = {
      common_options = {}
      repo_list = {
        "-svc-" = null
      }
    }
    tags = {}
  }

  assert {
    condition     = output.repo_info["-svc-"].repository_name == "padded/svc"
    error_message = "Expected leading/trailing hyphens trimmed from prefix and repo name, got '${output.repo_info["-svc-"].repository_name}'"
  }
}
