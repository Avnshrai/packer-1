## Jenkins
packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "ubuntu" {
  image  = "siddharth387/coredge:74-f9e1f58"
  commit = true
  changes = [
    "ENV APP_VERSION 2.401.",
    "ENV PATH /opt/bitnami/common/bin:/opt/bitnami/java/bin:$PATH",
    "ENV JAVA_HOME /opt/bitnami/java",
    "ENV JENKINS_HOME /opt/bitnami/jenkins",
    "ENV BITNAMI_APP_NAME jenkins",
    "EXPOSE 8080 8443 50000",
    "USER 1001",
    "ENTRYPOINT [\"/opt/bitnami/scripts/jenkins/entrypoint.sh\"]",
    "CMD [\"/opt/bitnami/scripts/jenkins/run.sh\"]"
  ]
}

build {
  name = "Coredge-image"
  sources = [
    "source.docker.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "apt-get update",
      # "sudo adduser --disabled-password --gecos \"\" grafana",
      # "sudo usermod -aG sudo grafana",
      "apt-get -y install ca-certificates curl fontconfig git jq libfontconfig1 openssh-client procps unzip zlib1g",
      "mkdir -p /opt/bitnami",
      "mkdir -p /tmp/bitnami/pkg/cache/ && cd /tmp/bitnami/pkg/cache/",
      "curl -SsLf \"https://downloads.bitnami.com/files/stacksmith/render-template-1.0.5-6-linux-amd64-debian-11.tar.gz\" -O",
      "curl -SsLf \"https://downloads.bitnami.com/files/stacksmith/java-11.0.19-7-2-linux-amd64-debian-11.tar.gz\" -O",
      "curl -SsLf \"https://downloads.bitnami.com/files/stacksmith/jenkins-2.401.1-0-linux-amd64-debian-11.tar.gz\" -O",
      "tar -zxf render-template-1.0.5-6-linux-amd64-debian-11.tar.gz -C /opt/bitnami --strip-components=2 --no-same-owner",
      "tar -zxf java-11.0.19-7-2-linux-amd64-debian-11.tar.gz -C /opt/bitnami --strip-components=2 --no-same-owner",
      "tar -zxf jenkins-2.401.1-0-linux-amd64-debian-11.tar.gz -C /opt/bitnami --strip-components=2 --no-same-owner",
      "rm -rf jenkins-2.401.1-0-linux-amd64-debian-11.tar.gz{,.sha256}",
      "rm -rf java-11.0.19-7-2-linux-amd64-debian-11.tar.gz{,.sha256}",
      "rm -rf render-template-1.0.5-6-linux-amd64-debian-11.tar.gz{,.sha256}",
      "apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives",
      "mkdir -p /opt/bitnami/jenkins/data",
      "chown -R 1001:1001 /opt/bitnami/",
      "chmod -R +x /opt/*"
      # "sh /opt/bitnami/scripts/java/postunpack.sh",
      # "sh /opt/bitnami/scripts/jenkins/postunpack.sh"
    ]
  }
  provisioner "file" {
    source      = "rootfs/"
    destination = "/"
  }
  provisioner "file" {
    source  = "prebuildfs/"
    destination = "/"
  }
  provisioner "shell" {
    inline = [
      "chmod -R +x /opt/*"
    ]
  }
  post-processor "docker-tag" {
    repository = "coredge/jenkins"
    tags = ["test"]
  }
}
