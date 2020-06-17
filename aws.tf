provider "aws" {
  region = "ap-south-1"
  profile = "niveditams"
}
resource "aws_key_pair" "nivi12" {
  key_name = "nivi12"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAk7cWVvalRLCM99hQ7/MN60nYvHU29Df6huN977gzzpd0vPiBvJnTyrTQJRDV9cQE5X+HxpL8YRgJkK+b1eqWi9MqD7SuUe9gnnJKUdare/6XJM3j7V9TAmYCRGG4ZY5uaxpjcZ5iGvZBtKHLRa8vIkDGKyxNBquqIwoqZ31AXxaars3wmXTceSWaAQ4dVLPrMhPqs1Bymg3iUL7NcJykK+rxUM4qHumN9QM91T0Pym7953+CU5pdSu9qdYDF+eQunXdNwuRJqn/pLEgtvBFQziXDQ2W/UhiE9S88lUChi5vSqxtu/XFQM3pa5rHAJ5OYmxhKVenf80KPx0yRm2XyvQ== rsa-key-20200615"
}

  resource "aws_security_group" "group1" {
  name = "group1"
  description="allow ssh and http traffic"
ingress{
	from_port = 22
	to_port = 22
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0]"
}
ingress{
	from_port = 80
	to_port = 80
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
}
ingress{
	from_port = 443
	to_port = 443
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
}
egress{
	from_port = 22
	to_port = 22
	protocol = "-1"
	cidr_blocks = ["0.0.0.0/0"]


resource "aws_instance" "web" {
ami = "ami-0447a12f28fddb066"
instance_type = "t2.micro"
key_name = "nivi12"
security_groups = ["group1"]

conection {
	type = "ssh"
	user = "ec2-user"
	private_key = file("nivi12.pem")
	host = aws_instance.web.public_ip
}

provisioner "remote-exec" {
	inline = [
		"sudo yum install httpd php git -y",
		"sudo systemctl restart httpd",
		"sudo systemctl enable httpd",
	]
}

tags = {
	Name = "nivi1os"
 }
}
resource "aws_ebs_volume" "myvol" {
	availability_zone = aws_instance.web.availability_zone
	size = 1
	tags = {
		Name = "myvol"
	}
}

resource "aws_volume_attachment" "ebs_att" {
	device_name = "/dev/sdh"
	volume_id = "${aws_ebs_volume.myvol.id}"
	instance_id = "${aws_instance.web.id}"
	force_detach = true
}
resource "null_resource" "nullremote" {

depends_on = [
	aws_volume_attachment.ebs_att,
   ]

connection {
	type = "ssh"
	user = "ec2-user"
	private_key = file("nivi12.pem")
	host = aws_instance.web.public_ip
}

provisioner "remote-exec" {
	inline = [
		"sudo mkfs.ext4  /dev/xvdh",
		"sudo mount  /dev/xvdh  /var/www/html",
		"sudo rm -rf /var/www/html/*",
		"sudo git clone https://github.com/NiveditaMShinde/Task1-HybridMultiCloud.git /var/www/html/"
	]
}
}
resource "aws_s3_bucket" "b" {
		bucket = "niveditabucket"
		acl = "private"
	tags = {
		Name = "mybucket"
}
}
locals {
	s3_origin_id = "s3-niveditabucket"
}
output "b" {
	value = aws_s3_bucket.b
}
resourse "aws_cloudfront_origin_access_identity" "identity" {
	comment = "Some comment"
}
output "origin_access_identity" {
	value = aws_cloudfront_origin_access_identity.identity
} 
resource "aws_cloudfront_distribution" "cloudfront1" {
	enabled = true
	is_ipv6_enabled = true
	wait_for_deployment = false	
	origin {
		domain_name = "${aws_s3_bucket.b.bucket_regional_domain_name}"
		origin_id = local.s3_origin_id
	s3_origin_config {
		origin_access_identity = "${aws_cloudfront_origin_access_identity.identity.cloudfront_access_identity_path}"
}
}
	default_cache_behavior {
		allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
		cached_methods = ["GET", "HEAD"]
		target_origin_id = local.s3_origin_id
	forwarded_values {
		query_string = false

		cookies {
			forward = "none"
		}
	}
	
	viewer_protocol_policy = "redirect-to-https"
	min_ttl = 0
	default_ttl = 3600
	max_ttl = 86400
}
resource "aws_s3_bucket_object" "object" {
	bucket = "niveditabucket"
	key = "cloud.png"
}
