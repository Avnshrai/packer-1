#### Node Exporter Packer file #####
packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "ubuntu" {
  image  = "coredgeio/ubuntu-base-beta:v1"
  commit = true
  changes = [
    "EXPOSE 9100",
    "ENTRYPOINT [ \"/opt/coredge/node-exporter/bin/node_exporter\"]"
  ]
}

build {
  name = "Coredge-image"
  sources = [
    "source.docker.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "mkdir /root/.aws"
    ]
  }

  provisioner "file" {
    source = "credentials"
    destination = "/root/.aws/credentials"
  }

  provisioner "file" {
    source = "config"
    destination = "/root/.aws/config"
  }

  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get install -y wget",
      "apt-get -y install sudo ca-certificates curl tar",
      "mkdir /opt/coredge",
      "mkdir /s5cmd && cd /s5cmd",
      "wget https://github.com/peak/s5cmd/releases/download/v2.1.0/s5cmd_2.1.0_Linux-64bit.tar.gz",
      "tar -xzvf s5cmd_2.1.0_Linux-64bit.tar.gz",
      "chmod +x s5cmd",
      "cp /s5cmd/s5cmd /sbin",
      "mkdir -p /tmp/coredge/pkg/cache/ && cd /tmp/coredge/pkg/cache/",
      "s5cmd --stat cp 's3://coredgeapplications/node-exporter/v1.6.0.1-amd64/node-exporter-1.6.0-1-linux-amd64-debian-11.tar.gz' .",
      "tar -zxf node-exporter-1.6.0-1-linux-amd64-debian-11.tar.gz -C /opt/coredge --strip-components=2",
      "chmod g+rwX /opt/coredge",
      "cd",
      "echo -e \"\n\" > /etc/issue", # Remove the Ubuntu version information and replace it with a new lines,
      "rm -rf /s5cmd",
      "rm /sbin/s5cmd",
      "apt purge wget -y",
      "apt purge curl -y",
      "apt purge passwd -y --allow-remove-essential",
      "rm -rf /tmp/coredge/pkg/cache/node-exporter-1.6.0-1-linux-amd64-debian-11.tar.gz",
      "rm -rf /root/.aws"
    ]
  }

  provisioner "shell" {
    inline = [
      "chmod -R +x /opt/*"
    ]
  }
  post-processor "docker-tag" {
    repository = "coredge/node-exporter-packer"
    tags = ["v1"]
  }
}
