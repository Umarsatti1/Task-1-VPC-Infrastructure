output "ec2_instance_public_ip" {
    value = aws_instance.public_ec2.public_ip
    description = "Public IP Address of EC2s in public subnet"
}

output "public_ec2_private_ip" {
    value = aws_instance.public_ec2.private_ip
    description = "Private IP Address of EC2s in public subnet"
}

output "private_ec2_private_ip" {
    value = aws_instance.private_ec2.private_ip
    description = "Private IP Address of EC2s in private subnet"
}

output "s3_bucket_name" {
    value = aws_s3_bucket.s3_bucket.bucket
    description = "S3 Bucket Name"
}