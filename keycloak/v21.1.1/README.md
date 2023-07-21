## How we are using Packer

```hcl
packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}
```
In above section we are defining the Packer version which is `0.0.7` in my case along with docker source.

```hcl
source "docker" "ubuntu" {
  image  = "coredgeio/ubuntu-base-beta:v1"
  commit = true
  changes = [
    "ENV APP_VERSION 21.1.1",
    "ENV COREDGE_APP_NAME keycloak",
    "ENV JAVA_HOME /opt/coredge/java",
    "ENV PATH /opt/coredge/common/bin:/opt/coredge/java/bin:/opt/coredge/keycloak/bin:$PATH",
    "WORKDIR /opt/coredge/keycloak",
    "USER 65100",
    "ENTRYPOINT [ \"/opt/coredge/scripts/keycloak/entrypoint.sh\" ]",
    "CMD [ \"/opt/coredge/scripts/keycloak/run.sh\" ]"
  ]
}
```

Choosing our own ubuntu base image as `coredgeio/ubuntu-base-beta:v1` and defining environment variables, workdir, CMD and Entrypoint for `keycloak` service. This is sort of a docker override.

```hcl
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
    destination = "/"
  }
  provisioner "file" {
    source  = "prebuildfs/"
    destination = "/"
  }
  provisioner "shell" {
    inline = [
      "chmod -R +x /opt/*",
      "usermod -G root,sudo core"
    ]
  }
```
In the `build` section we require AWS cli access to fetch required binaries from AWS S3 bucket. So we are creating `.aws` directory over the `/root/.aws` and placing `credentials` and `config` in the same.
Also we are copying necessary scripts and files required to the destination. We are also changing default container `core` user permissions for relevant access.

```hcl
provisioner "shell" {
    inline = [
      "apt-get update",
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get -y install wget ca-certificates curl krb5-user libaio1 procps zlib1g",
      "mkdir /s5cmd",
      "wget -P /s5cmd https://github.com/peak/s5cmd/releases/download/v2.1.0/s5cmd_2.1.0_Linux-64bit.tar.gz",
      "tar -xzvf /s5cmd/s5cmd_2.1.0_Linux-64bit.tar.gz -C /s5cmd",
      "chmod +x /s5cmd/s5cmd",
      "cp /s5cmd/s5cmd /sbin",
      "mkdir -p /tmp/coredge/pkg/cache/ && cd /tmp/coredge/pkg/cache/",
      "s5cmd --stat cp 's3://coredgeapplications/keycloak/v21.1.1-0/keycloak-21.1.1-0-linux-amd64-debian-11.tar.gz' .",
      "s5cmd --stat cp 's3://coredgeapplications/java/v17.0.7-7-2/java-17.0.7-7-2-linux-amd64-debian-11.tar.gz' .",
      "s5cmd --stat cp 's3://coredgeapplications/wait-for-port/1.0.6-9/wait-for-port-1.0.6-9-linux-amd64-debian-11.tar.gz' .",
      "tar -zxf 'keycloak-21.1.1-0-linux-amd64-debian-11.tar.gz' -C /opt/coredge --strip-components=2",
      "tar -zxf 'java-17.0.7-7-2-linux-amd64-debian-11.tar.gz' -C /opt/coredge --strip-components=2",
      "tar -zxf 'wait-for-port-1.0.6-9-linux-amd64-debian-11.tar.gz' -C /opt/coredge --strip-components=2",
      "rm -rf /tmp/coredge/pkg/cache/keycloak-21.1.1-0-linux-amd64-debian-11.tar.gz",
      "rm -rf /tmp/coredge/pkg/cache/java-17.0.7-7-2-linux-amd64-debian-11.tar.gz",
      "rm -rf /tmp/coredge/pkg/cache/wait-for-port-1.0.6-9-linux-amd64-debian-11.tar.gz",
      "chmod g+rwX /opt/coredge/",
      "ls -lrth /opt/coredge/scripts",
      "ls -lrth /opt/coredge/scripts/java",
      "/bin/bash -o pipefail -c '/opt/coredge/scripts/java/postunpack.sh'",
      "/bin/bash -o pipefail -c '/opt/coredge/scripts/keycloak/postunpack.sh'",
      "chown -R core:core /opt/coredge/",
      "apt-get autoremove --purge -y curl wget",
      "apt-get update && apt-get upgrade -y && apt-get clean",
      "rm -rf /var/lib/apt/lists /var/cache/apt/archives",
      "rm -rf /s5cmd && rm /sbin/s5cmd && rm -rf /root/.aws"
    ]
  }
```
In the `build` section we are using another `shell` provisioner to run our shell commands - Installing necessary packages, binaries, creating required directories. We are also installing `s5cmd`. We are also deleting unnecessary files and packages to keep the image size small. 

*Note-* *Here we are fetching Coredge custom keycloak binary from AWS S3 using `s5cmd`.*

In Provisioner section defining all the requirements for `grafana`.

```hcl
post-processor "docker-tag" {
    repository = "coredge/keycloak"
    tags = ["v21.1.1-0"]
  }
```
`Post-Processor` section helps to provide image tag. It will build the image thru packer and make it available locally with name & tag provided in the `Post-Processor` section.
