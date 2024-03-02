# create variable for region with value and default value us-east-1

variable "region" {
  type    = string
  # default = "ap-south-1"
}

# create variable for bucket name with value and default value tf-state-bucket-name and validate it with regex

variable "bucket_name" {
  type        = string
  default     = "tf-state-bucket-name"
  description = "This is the name of the bucket"
  validation {
    condition     = can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*$", var.bucket_name))
    error_message = "The bucket name can only contain lowercase letters, numbers, periods, and hyphens."
  }
}

# create codeCommit variable for reposatry name
# create codeCommit description variable

variable "repository_name" {
  type    = string
  default = "tf-codecommit-repo"
}

 variable "repository_description" {
  type    = string
  default = "This is the repository for codecommit"
}

# create variable name of the codepipeline
# create variable for denfine branch name at stage source for file commit
# create  variable for role and role policy name
variable "codepipeline_name" {
  type    = string
  default = "tf-codepipeline"
}
 variable "codecommit_branch_name" { //create this value manually
  type    = string
  default = "master"
}
 variable "codepipeline_role_name" {
  type    = string
  default = "tf-codepipeline-role"
}
 variable "codepipeline_role_policy_name" {
  type    = string
  default = "tf-codepipeline-role-policy"
} 

# create variable for CodeBuild resources like name,description.

variable "codebuild_project_name" {     //not able to define name for codebuild project name
  type    = string
  default = "tf-codebuild-project"
}

 variable "codebuild_project_description" {
  type    = string
  default = "This is the project for codebuild"
}

# create variable for codebuild role

variable "codebuild_role_name" {
  type    = string
  default = "tf-codebuild-role"
}