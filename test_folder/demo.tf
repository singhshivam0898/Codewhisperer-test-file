//*-----------------------1st iteration code fro cloudfront-----------------------*//

resource "aws_cloudfront_distribution" "my-distribution" {
  origin {
    domain_name = aws_s3_bucket.my-bucket.bucket_domain_name
    origin_id   = local.s3_origin_id        #not able to create
  }

  enabled         = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id     #not able to create

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
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
} 

output "cloudfront_domain_name" {
    value = aws_cloudfront_distribution.my-cloudfront-distribution.domain_name
  }
   output "cloudfront_distribution_id" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.id
  }
   output "cloudfront_etag" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.etag
  }
   output "cloudfront_hosted_zone_id" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.hosted_zone_id
  }
   output "cloudfront_last_modified_time" { 
     value = aws_cloudfront_distribution.my-cloudfront-distribution.last_modified_time
  }
   output "cloudfront_status" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.status
  }
   output "cloudfront_domain_name" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.domain_name
  }
   output "cloudfront_arn" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.arn
  }
   output "cloudfront_caller_reference" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.caller_reference
  }
   output "cloudfront_aliases" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.aliases
  }
   output "cloudfront_origins" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.origins
  }
   output "cloudfront_default_cache_behavior" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.default_cache_behavior
  }
   output "cloudfront_cache_behaviors" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.cache_behaviors
  }
   output "cloudfront_custom_error_responses" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.custom_error_responses
  }
   output "cloudfront_comment" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.comment
  }
   output "cloudfront_logging_config" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.logging_config
  }
   output "cloudfront_price_class" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.price_class
  }
   output "cloudfront_enabled" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.enabled
  }
   output "cloudfront_is_ipv6_enabled" { 
     value = aws_cloudfront_distribution.my-cloudfront-distribution.is_ipv6_enabled
  }
   output "cloudfront_restrictions" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.restrictions
  }
   output "cloudfront_web_acl_id" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.web_acl_id
  }
   output "cloudfront_http_version" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.http_version
  }
   output "cloudfront_viewer_certificate" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.viewer_certificate
  }
   output "cloudfront_restrictions" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.restrictions
  }
   output "cloudfront_tags_all" {
     value = aws_cloudfront_distribution.my-cloudfront-distribution.tags_all
  }
   output "cloudfront_origin_access_identity_iam_arn" {
     value = aws_cloudfront_origin_access_identity.my-cloudfront-origin-access-identity.iam_arn
  }
   output "cloudfront_origin_access_identity_cloudfront_access_identity_path" {
      value = aws_cloudfront_origin_access_identity.my-cloudfront-origin-access-identity.cloudfront_access_identity_path
  }
   output "cloudfront_origin_access_identity_id" {
      value = aws_cloudfront_origin_access_identity.my-cloudfront-origin-access-identity.id
  }
   output "cloudfront_origin_access_identity_etag" {
      value = aws_cloudfront_origin_access_identity.my-cloudfront-origin-access-identity.etag
  }
   output "cloudfront_origin_access_identity_comment" {
      value = aws_cloudfront_origin_access_identity.my-cloudfront-origin-access-identity.comment
  }
   output "cloudfront_origin_access_identity_tags_all" {
      value = aws_cloudfront_origin_access_identity.my-cloudfront-origin-access-identity.tags_all
  }


  //-----------------------------------------------------Code pipeline initial iteration code ----------------------------------------------------------//

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
       output_artifacts = ["Source"]

       configuration = {
         RepositoryName       = aws_codecommit_repository.my-codecommit-repository.repository_name
         BranchName           = var.repository_branch
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
       input_artifacts  = ["Source"]
       output_artifacts = ["Build"]
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
       provider        = "ECS"
       version         = "1"
       input_artifacts = ["Build"]

       configuration = {
         ClusterName = aws_ecs_cluster.my-ecs-cluster.name
         ServiceName = aws_ecs_service.my-ecs-service.name
       }
     }
   }
   depends_on = [aws_codebuild_project.my-codebuild-project]

   tags = {
     Environment = "production"
   }

 }


 //*---------------------------------------------Codebuild 1st iteration code--------------------------------*//

 resource "aws_codebuild_project" "my-codebuild-project" {
  name          = var.codebuild_project_name
  description   = var.codebuild_project_description
  build_timeout = "5"
  service_role  = aws_iam_role.my-codebuild-role.arn

  source {
    type     = "CODECOMMIT"
    location = aws_codecommit_repository.my-codecommit-repository.clone_url_http
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                 = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
  }         

  artifacts {
    type = "S3"
    location = aws_s3_bucket.my-bucket.bucket
    namespace_type = "BUILD_ID"
    packaging = "NONE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }
  tags = {
     Environment = "production"
  }
} //not able to suggest module ending at this point