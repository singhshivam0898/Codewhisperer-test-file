# create provider for aws
provider "aws" {
  region = var.region
}

#  create the Bucket resource with the following configurations
#         - Enable encryption
#         - Enable versioning
#         - static website hosting

resource "aws_s3_bucket" "my-bucket" {
  bucket = var.bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

  locals {
    s3_origin_id = "myS3Origin"
}
# step 2: cloudfront distribution
# Generate the cloudfront distribution resource with the following configurations:
          # - create the cloudfront distribution
          # - specify the following origin configurations:
          #       - S3 origin source
          #       - specify an origin name
          #       - create a new Origin Access Control
          #       - use the Origin Access Control to access the existing bucket
          # - specify the default object
          # - BucketPolicy - Add an S3 bucket policy to allow access from the CloudFront distribution

resource "aws_cloudfront_distribution" "my-cloudfront-distribution" {
  origin {
    domain_name = aws_s3_bucket.my-bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.my-cloudfront-origin-access-identity.cloudfront_access_identity_path
    }
  }

# add default root object
  default_root_object = "index.html" 
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "My CloudFront distribution"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    } // close this point manually
  }  // close this point manually
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  tags = {
     Environment = "production"
  }
  depends_on = [ aws_s3_bucket_policy.my-bucket-policy ]
  
}

resource "aws_cloudfront_origin_access_identity" "my-cloudfront-origin-access-identity" {
  comment = "My CloudFront OAI"
}
   resource "aws_s3_bucket_policy" "my-bucket-policy" {
    bucket = aws_s3_bucket.my-bucket.id
    policy = data.aws_iam_policy_document.my-bucket-policy.json
  }
  
  data "aws_iam_policy_document" "my-bucket-policy" {
    statement {
      principals {
        type        = "AWS"
        identifiers = [aws_cloudfront_origin_access_identity.my-cloudfront-origin-access-identity.iam_arn]
      }
      actions   = ["s3:GetObject"]
      resources = ["${aws_s3_bucket.my-bucket.arn}/*"]
    }
  }
  
# Step 4: CodeCommit Repository stack
# create CodeCommit repository stack name
 resource "aws_codecommit_repository" "my-codecommit-repository" {
   repository_name = var.repository_name
   description     = var.repository_description
 }
  
# Step 5: CodeBuild Project : 
#       Generate the terraform stack for the following steps:    
#         - Specify the code build project name
#         - Configure it to use the CodeCommit repository as the source.
#         - Choose the Environment as Managed Image
#         - Specify the buildspec.yml file for build instructions.
#         - In Artifact choose Type as S3 Bucket and specify the name of our configured bucket and choose namespace type as Build ID and artifact package type as None

resource "aws_codebuild_project" "my-codebuild-project" {
  name          = var.codebuild_project_name
  description   = var.codebuild_project_description
  build_timeout = "5"
  service_role  = aws_iam_role.my-codebuild-role.arn

  source {
    type      = "CODECOMMIT"
    location  = aws_codecommit_repository.my-codecommit-repository.clone_url_http
    buildspec = "buildspec.yml"   // not suggest the buildspec till 2rd iteration after doing some modification in prompt and run the whole prompt again it gives us the required output
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "REACT_APP_API_URL"
      value = "https://api.example.com"
    }
  }

  artifacts {
    type = "S3"
    location = aws_s3_bucket.my-bucket.bucket
    namespace_type = "BUILD_ID"
    packaging = "NONE"
  }
   
  cache {
    type  = "S3" //on 1st iteration it's given the value "LOCAL"
    location = aws_s3_bucket.my-bucket.bucket
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }
  depends_on = [ aws_s3_bucket_policy.my-bucket-policy ]  // not provided this at 1st iteration at this block in 2nd iteratiion it suggest this value
    
    tags = {
    Environment = "production"
  } 

}
/*------------------------S3 bucket policy sugget by codewhisperer in 2nd iteration-----------------------*/
/*------------------------ Duplicate data "aws_iam_policy_document" configuration suggeted-----------------------*/

#  resource "aws_s3_bucket_policy" "my-bucket-policy" {
#     bucket = aws_s3_bucket.my-bucket.id
#     policy = data.aws_iam_policy_document.my-bucket-policy.json
#   }
/*------------------------ Duplicate data "aws_iam_policy_document" configuration suggeted-----------------------*/

  # data "aws_iam_policy_document" "my-bucket-policy" {
  #   statement {
  #     principals {
  #       type        = "AWS"
  #       identifiers = [aws_cloudfront_origin_access_identity.my-cloudfront-origin-access-identity.iam_arn]
  #     }
  #     actions   = ["s3:GetObject"]
  #     resources = ["${aws_s3_bucket.my-bucket.arn}/*"]
  #   }
  # }

# create iam policy for codebuild role
 resource "aws_iam_role" "my-codebuild-role" {
   name = var.codebuild_role_name
   assume_role_policy = data.aws_iam_policy_document.my-codebuild-role-assume-policy.json
 }
 
 data "aws_iam_policy_document" "my-codebuild-role-assume-policy" {
   statement {
     actions = ["sts:AssumeRole"]
     principals {
       type = "Service"
       identifiers = ["codebuild.amazonaws.com"]
     }
   }
 }

# Step 6: CodePipeline :
#             - Create a CodePipeline pipeline for building and deploying your React project.
#             Stage 1: Source
#             - Retrieve source code from the existing AWS CodeCommit repository
#             Stage 2: Build
#             - Build the React project using CodeBuild to the existing CodeBuild project
#             Stage 3: Deploy
#             - use CodeDeploy to deploy the built React project to the existing S3 bucket

resource "aws_codepipeline" "my-codepipeline" {
  name     = var.codepipeline_name
  role_arn = aws_iam_role.my-codepipeline-role.arn

  artifact_store {
    location = aws_s3_bucket.my-bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        RepositoryName = aws_codecommit_repository.my-codecommit-repository.repository_name
        BranchName     = var.codecommit_branch_name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.my-codebuild-project.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["BuildArtifact"]

      configuration = {
        BucketName = aws_s3_bucket.my-bucket.bucket
        Extract    = "false"
      }
    }
  }
  tags = {
     Environment = "production"
  }
}
  resource "aws_iam_role" "my-codepipeline-role" {
    name = var.codepipeline_role_name
   assume_role_policy = data.aws_iam_policy_document.my-codepipeline-role-assume-policy.json
 }
 
 data "aws_iam_policy_document" "my-codepipeline-role-assume-policy" {
   statement {
     actions = ["sts:AssumeRole"]
     principals {
       type = "Service"
       identifiers = ["codepipeline.amazonaws.com"]
     }
   }
 }
  resource "aws_iam_role_policy" "my-codepipeline-role-policy" {
    name = var.codepipeline_role_policy_name
   role = aws_iam_role.my-codepipeline-role.id
   policy = data.aws_iam_policy_document.my-codepipeline-role-policy.json
 }
  data "aws_iam_policy_document" "my-codepipeline-role-policy" {
   statement {
     actions = ["codecommit:GetBranch", "codecommit:GetCommit", "codecommit:UploadArchive", "codecommit:GetUploadArchiveStatus", "codebuild:BatchGetBuilds", "codebuild:StartBuild"]
     resources = ["*"]
   }
 }
  /*resource "aws_iam_role_policy_attachment" "my-codepipeline-role-policy-attachment" {
    role       = aws_iam_role.my-codepipeline-role.name
   policy_arn = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"   //no suggestion from codewhisperer for policy arn value here for codepipline not even a default value format
 }*/