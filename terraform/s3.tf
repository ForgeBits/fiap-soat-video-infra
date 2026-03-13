resource "aws_s3_bucket" "video_storage" {
  bucket = "fiapx-storage-${random_id.id.hex}"
}