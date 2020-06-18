
//using aws


provider "aws" {
  region     = "ap-south-1"
  profile    = "anurag007"
}

//Creating a key

resource "tls_private_key" "tls_key" {
 algorithm = "RSA"
}

//Generating Key-Value Pair

resource "aws_key_pair" "generated_key" {
 key_name = "anurag14"
 public_key = "${tls_private_key.tls_key.public_key_openssh}"

depends_on = [
  tls_private_key.tls_key
 ]
}

//Saving key

resource "local_file" "key-file" {
 content = "${tls_private_key.tls_key.private_key_pem}"
 filename = "anurag14.pem"

depends_on = [
  tls_private_key.tls_key, 
  aws_key_pair.generated_key
 ]
}



resource "aws_security_group" "HttpAndSsh" {
  name        = "HttpAndSsh"
  description = "Allow HTTP inbound traffic"


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "task1sec"
  }
}



//launch instance

resource "aws_instance" "taskOs1" {
 ami = "ami-0447a12f28fddb066"
 instance_type = "t2.micro"
 key_name = "${aws_key_pair.generated_key.key_name}"
 security_groups = ["${aws_security_group.HttpAndSsh.name}"]
 tags = {
  Name = "taskOs1"
 }
}

//create ebs

resource "aws_ebs_volume" "myebs" {
   availability_zone = aws_instance.taskOs1.availability_zone
   size = 1
  tags = {
      Name = "taskEbs1"
   }
}

// To attach the ebs volume created
resource "aws_volume_attachment" "ebs_attach" {
   device_name = "/dev/sdh"
   volume_id   = "${aws_ebs_volume.myebs.id}"
   instance_id = "${aws_instance.taskOs1.id}"
   force_detach = true
}

// For Output

output "myos_ip" {
  value = aws_instance.taskOs1.public_ip
}

//format and mount

resource "null_resource" "nullremote"{
 depends_on = [
     aws_volume_attachment.ebs_attach,
 aws_security_group.HttpAndSsh,
    aws_key_pair.generated_key 
  ]

connection{
    type = "ssh"
    user = "ec2-user"
    private_key = file("C:/Users/KIIT/Desktop/tera/finish/anurag14.pem")
    host = aws_instance.taskOs1.public_ip
}

provisioner "remote-exec"{
    inline = [
       "sudo yum install httpd  php git -y",
       "sudo systemctl restart httpd",
       "sudo systemctl enable httpd",
       "sudo mkfs.ext4  /dev/xvdh",
       "sudo mount  /dev/xvdh  /var/www/html",
       "sudo rm -rf /var/www/html/*",
       "sudo git clone https://github.com/anuragkumar14/cloudd.git /var/www/html/"
    ]
  }
}

// Creating S3 bucket
resource "aws_s3_bucket" "anurag07hawkbucket7" {
  bucket = "anurag07hawkbucket7"
  acl    = "public-read"
  tags = {
  Name = "anurag07hawkbucket7"
 }
}



//adding object to s3 bucket


resource "aws_s3_bucket_object" "anurag07hawkbucket7" {
  bucket = "anurag07hawkbucket7"
  key    = "Wallpaper2_1920x1200.jpg"
  source = "C:/Users/KIIT/Downloads/Wallpaper2_1920x1200.jpg"
  acl = "public-read"
}


//create CloudFront 


locals {
  s3_origin_id = "aws_s3_bucket.anurag07hawkbucket7.id"
}


resource "aws_cloudfront_distribution" "MyCloudFront" {
  origin {
    domain_name = "${aws_s3_bucket.anurag07hawkbucket7.bucket_regional_domain_name}"
    origin_id   = "${aws_s3_bucket.anurag07hawkbucket7.bucket}"
  }


  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CLOUDFRONT FOR S3 DISTRIBUTION "
  


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.anurag07hawkbucket7.bucket}"


    forwarded_values {
      query_string = false


      cookies {
        forward = "none"
      }
    }


    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "IN"]
    }
  }


  


  tags = {
    Environment = "automation in industry"
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }
  retain_on_delete = true
}


//output for cloudFront Ip


output "cloudfrontIP"{
  value=aws_cloudfront_distribution.MyCloudFront.domain_name
}


//creating  Snapshot


resource "aws_ebs_snapshot" "createsnapshot" {
  volume_id = "${aws_ebs_volume.myebs.id}"


  tags = {
    Name = "createdsnapshotebs"
  }

}
