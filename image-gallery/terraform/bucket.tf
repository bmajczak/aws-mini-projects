resource "aws_s3_bucket" "image_gallery" {
  bucket        = var.image_gallery
  force_destroy = true

}

resource "aws_s3_bucket_policy" "image_gallery_policy" {
  bucket = aws_s3_bucket.image_gallery.id
  policy = file("${path.module}/resources/policy-gallery.json")
}

resource "aws_s3_bucket_public_access_block" "image_gallery_block" {
  bucket = aws_s3_bucket.image_gallery.id


  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = false
  block_public_policy     = false
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.image_gallery.id

  index_document {
    suffix = "index.html"
  }
}




resource "aws_s3_bucket" "image_storage" {
  bucket        = var.image_storage
  force_destroy = true
}

resource "aws_s3_bucket_policy" "image_storage_policy" {
  bucket = aws_s3_bucket.image_storage.id
  policy = file("${path.module}/resources/policy-storage.json")

}

resource "aws_s3_bucket_public_access_block" "image_storage_block" {
  bucket = aws_s3_bucket.image_storage.id


  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = false
  block_public_policy     = false
}

resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.image_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://static-image-gallery-654.s3.eu-central-1.amazonaws.com"]
    expose_headers  = [""]
    max_age_seconds = 3000
  }
}