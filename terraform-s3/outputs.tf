output "bucket_name" {
  description = "Nome do bucket S3"
  value       = aws_s3_bucket.video_storage.id
}

output "bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.video_storage.arn
}

output "bucket_region" {
  description = "Região do bucket S3"
  value       = aws_s3_bucket.video_storage.region
}

output "bucket_domain_name" {
  description = "Domain name do bucket S3"
  value       = aws_s3_bucket.video_storage.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name do bucket S3"
  value       = aws_s3_bucket.video_storage.bucket_regional_domain_name
}

