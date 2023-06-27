## Grafna
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
    "ENV APP_VERSION 9.5.3",
    "ENV COREDGE_APP_NAME grafana",
    "ENV PATH /opt/coredge/grafana/bin:$PATH",
    "EXPOSE 3000",
    "WORKDIR /opt/coredge/grafana",
    "USER 65100",
    "CMD [ \"/opt/coredge/scripts/grafana/run.sh\" ]",
    "ENTRYPOINT [ \"/opt/coredge/scripts/grafana/entrypoint.sh\"]"
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

  provisioner "file" {
    source      = "rootfs/"
    destination = "opt/"
  }
  provisioner "file" {
    source  = "prebuildfs/opt/"
    destination = "opt/"
  }
  provisioner "shell" {
    inline = [
      "chmod -R +x /opt/*",
      "usermod -G root,sudo core"
    ]
  }

  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get -y install wget ca-certificates curl libfontconfig procps",
      "mkdir /s5cmd && cd /s5cmd",
      "wget https://github.com/peak/s5cmd/releases/download/v2.1.0/s5cmd_2.1.0_Linux-64bit.tar.gz",
      "tar -xzvf s5cmd_2.1.0_Linux-64bit.tar.gz",
      "chmod +x s5cmd",
      "cp /s5cmd/s5cmd /sbin",
      "mkdir -p /tmp/coredge/pkg/cache/ && cd /tmp/coredge/pkg/cache/",
      "s5cmd --stat cp 's3://coredgeapplications/grafana/v9.5.3/grafana-9.5.3-0-linux-amd64-debian-11.tar.gz' .",
      "tar -zxf grafana-9.5.3-0-linux-amd64-debian-11.tar.gz -C /opt/coredge --strip-components=2",
      "rm -rf grafana-9.5.3-0-linux-amd64-debian-11.tar.gz",
      "rm -rf /tmp/coredge/pkg/cache/grafana-9.5.3-0-linux-amd64-debian-11.tar.gz",
      "sudo chmod g+rwX /opt/coredge/",
      "/bin/bash -o pipefail -c '/opt/coredge/scripts/grafana/postunpack.sh'",
      "chown -R core:core /opt/coredge/",
      "apt-get autoremove --purge -y curl wget",
      "apt-get update && apt-get upgrade -y && apt-get clean",
      "rm -rf /var/lib/apt/lists /var/cache/apt/archives",
      "rm -rf /s5cmd && rm /sbin/s5cmd && rm -rf /root/.aws"
    ]
  }

  post-processor "docker-tag" {
    repository = "coredge/baseos-beta"
    tags = ["v9.5.3-0"]
  }
}
