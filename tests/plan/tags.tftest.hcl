mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

# Test 2.7: Tag merge — plan succeeds with all tag levels defined
# Note: We cannot inspect the merged tags through the upstream module boundary
# (it only exposes repository_name, _arn, _url, _registry_id).
# These tests validate that the tag merge logic is syntactically correct and
# the plan succeeds with various tag combinations.
run "tag_merge_all_levels" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {
        tags = {
          "cost-centre" = "CC-COMMON"
          "project-id"  = "PROJ-COMMON"
        }
      }
      repo_list = {
        "tag-override-repo" = {
          tags = {
            "project-id" = "PROJ-OVERRIDE"
            "service-id" = "SVC-OVERRIDE"
          }
        }
      }
    }
    tags = {
      "environment" = "test"
    }
  }

  assert {
    condition     = output.repo_info["tag-override-repo"].repository_name == "tag-override-repo"
    error_message = "Expected plan to succeed with all three tag levels defined"
  }
}

# Tag inheritance when repo has no overrides
run "tag_inheritance_no_override" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {
        tags = {
          "cost-centre" = "CC-COMMON"
          "project-id"  = "PROJ-COMMON"
        }
      }
      repo_list = {
        "basic-repo" = null
      }
    }
    tags = {
      "environment" = "test"
    }
  }

  assert {
    condition     = output.repo_info["basic-repo"].repository_name == "basic-repo"
    error_message = "Expected plan to succeed with tag inheritance from common_options"
  }
}

# No tags at any level
run "no_tags" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {}
      repo_list = {
        "no-tags-repo" = null
      }
    }
    tags = {}
  }

  assert {
    condition     = output.repo_info["no-tags-repo"].repository_name == "no-tags-repo"
    error_message = "Expected plan to succeed with no tags defined"
  }
}
