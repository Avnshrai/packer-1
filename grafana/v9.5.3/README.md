# How we are using Packer

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
```

Choosing our own ubuntu base image as `coredgeio/ubuntu-base-beta:v1` and defining environment variables, workdir, CMD and Entrypoint for `grafana` service. This is sort of a docker override.

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
```
In the `build` section we require AWS cli access to fetch binaries from AWS S3. So we are creating `.aws` directory over the `/root/.aws` and placing `credentials` and `config` in the same.
Also we are copying necessary scripts and files required to the destination. We are also changing default container `core` user permissions for relevant access.

```hcl
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
      "rm -rf grafana-9.5.3-0-linux-amd64-debian-11.tar.gz{,.sha256}",
      "sudo chmod g+rwX /opt/coredge/",
      "/bin/bash -o pipefail -c '/opt/coredge/scripts/grafana/postunpack.sh'",
      "chown -R core:root /opt/coredge/",
      "apt-get autoremove --purge -y curl wget",
      "apt-get update && apt-get upgrade -y && apt-get clean",
      "rm -rf /var/lib/apt/lists /var/cache/apt/archives",
      "rm -rf /s5cmd && rm /sbin/s5cmd && rm -rf /root/.aws",
      "rm -rf /tmp/coredge/pkg/cache/grafana-9.5.3-0-linux-amd64-debian-11.tar.gz{,.sha256}"
    ]
  }
```
In the `build` section we are using another `shell` provisioner to run our shell commands - Installing necessary packages, binaries, creating required directories. We are also installing `s5cmd`. We are also deleting unnecessary files and packages to keep the image size small. 

*Note-* *Here we are fetching Coredge custom grafana binary from AWS S3 using `s5cmd`.*

In Provisioner section defining all the requirements for `grafana`.

```hcl
post-processor "docker-tag" {
    repository = "coredge/baseos-beta"
    tags = ["v9.5.3-0"]
  }
}
```
`Post-Processor` section helps to provide image tag. It will build the image thru packer and make it available locally with name & tag provided in the `Post-Processor` section.
