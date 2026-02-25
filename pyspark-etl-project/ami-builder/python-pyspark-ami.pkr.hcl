packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.8.0"
    }
  }
}


source "amazon-ebs" "pyspark_mysql" {
  ami_name                    = "pyspark-mysql-{{timestamp}}"
  instance_type               = "t3.medium"
  region                      = "us-east-1"
  vpc_id                      = "vpc-0b6151bb9b43b3c35"
  subnet_id                   = "subnet-0cb1611a792ee89d9"
  
  # --- USE PUBLIC IP TO BYPASS SSM HANGS ---
  associate_public_ip_address = true
  ssh_interface               = "public_ip" 
  ssh_username                = "ubuntu"
  ssh_timeout                 = "15m"

  # Tells Packer to open Port 22 only for your local machine's IP
  temporary_security_group_source_public_ip = true

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] 
  }
}

build {
  sources = ["source.amazon-ebs.pyspark_mysql"]

     provisioner "shell" {
    inline = [
      "echo '>>> Waiting for cloud-init...'",
      "sleep 30",
      "sudo apt-get update -y",
      "sudo apt-get install -y python3-pip openjdk-11-jdk-headless curl",
      
      # 1. Install PySpark and MySQL Python libraries
      "echo '>>> Installing Python libraries...'",
      "pip3 install pyspark mysql-connector-python",
      
      # 2. Download MySQL JDBC Driver using CURL (Direct to destination)
      "echo '>>> Downloading MySQL JDBC Driver...'",
      "sudo mkdir -p /opt/spark/jars",
      "sudo curl -L -o /opt/spark/jars/mysql-connector-j-8.3.0.jar https://repo1.maven.org",
      
      # 3. Final verification
      "echo '>>> Verifying installation...'",
      "python3 -c 'import pyspark; print(\"PySpark: OK\")'",
      "if [ -f /opt/spark/jars/mysql-connector-j-8.3.0.jar ]; then echo 'JAR: OK'; else echo 'JAR: MISSING'; exit 1; fi"
    ]
  }

}
