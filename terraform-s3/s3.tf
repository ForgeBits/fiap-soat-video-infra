# ============================================
# S3 Bucket - FIAP Video Worker
# ============================================

resource "aws_s3_bucket" "video_storage" {
  bucket = var.bucket_name

  tags = {
    Name    = var.bucket_name
    Project = "FIAP SOAT Video Worker"
  }
}

# ============================================
# Acesso Público Permitido
# ============================================

resource "aws_s3_bucket_public_access_block" "video_storage" {
  bucket = aws_s3_bucket.video_storage.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ============================================
# Bucket Policy - Leitura Pública
# ============================================

resource "aws_s3_bucket_policy" "video_storage" {
  bucket = aws_s3_bucket.video_storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.video_storage.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.video_storage]
}

# ============================================
# CORS Configuration
# ============================================

resource "aws_s3_bucket_cors_configuration" "video_storage" {
  bucket = aws_s3_bucket.video_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

