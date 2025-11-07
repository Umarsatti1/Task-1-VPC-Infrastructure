variable "vpc_name" {
    default = "umar-vpc"
    description = "VPC name"
    type = string
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
    description = "VPC CIDR Block"
    type = string
}

variable "s3_bucket_name" {
    default = "umarsatti-s3-bucket-for-vpc-flow-logs"
    description = "S3 Bucket Name"
    type = string
}