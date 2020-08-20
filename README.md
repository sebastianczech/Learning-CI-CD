# Learning CI/CD

Notes, configuration files and scripts created while learning Docker, Kubernetes, Jenkins, Gitlab, Ansible, Terraform and KVM.

## Overview

[Solution proposal](https://app.lucidchart.com/documents/edit/bf943422-2c36-4820-9963-7439bd7eb89f) contains key technologies used for creating CI/CD in home environment. Details of my solution are available on [solution overview](diagrams/solution_overview.puml). Alternative to use plantUML there is a [Diagram as a code](https://diagrams.mingrammer.com/).

## Prepare VM for CI/CD learning

[Download Debian non-free netinst version](https://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/10.5.0+nonfree/amd64/iso-cd/firmware-10.5.0-amd64-netinst.iso) and after creating VM in VirtualBox and installing Debian, on host add IP address of the machine and copy SSH keys to enable passwordless access:

```bash
grep devops /etc/hosts
192.168.0.18  	devops

ssh-copy-id devops 
```

On VM add user to ``sudo`` group without password:

```bash
sudo adduser seba sudo

sudo visudo
seba   ALL=(ALL) NOPASSWD:ALL
```

After basic configuration use playbooks to automatically provision VM:

```bash
cd playbooks
./cicd.sh
```

## Docker 

For installing Docker I used great [tutorial](https://www.rechberger.io/tutorial-install-docker-using-ansible-on-a-remote-server/), which I modiifed to use [Docker on Debian](https://docs.docker.com/engine/install/debian/). Besides Docker, I installed Docker Compose and Ctop.

Besides creating single images for containers, in developing environment there is very useful pattern - [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/), which allow you aterfacts build in 1 container to be used on another one.

## Kubernetes

For learning there is a great Kubernetes - [K3s](https://k3s.io/).

## Docker Swarm

## Jenkins

### Installation

There are many ways to start journey - it's very simple to do it [using Docker](https://www.jenkins.io/doc/book/installing/#downloading-and-running-jenkins-in-docker), for which we need to do following commands:

```bash
docker network create jenkins
docker network ls

docker volume create jenkins-docker-certs
docker volume create jenkins-data
docker volume ls

docker container run --name jenkins-docker --rm --detach --privileged --network jenkins --network-alias docker --env DOCKER_TLS_CERTDIR=/certs --volume jenkins-docker-certs:/certs/client --volume jenkins-data:/var/jenkins_home --publish 2376:2376 docker:dind
docker container run --name jenkins-blueocean --rm --detach --network jenkins --env DOCKER_HOST=tcp://docker:2376 --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 --publish 8080:8080 --publish 50000:50000 --volume jenkins-data:/var/jenkins_home --volume jenkins-docker-certs:/certs/client:ro jenkinsci/blueocean

docker volume inspect jenkins-data 
sudo cat /var/lib/docker/volumes/jenkins-data/_data/secrets/initialAdminPassword 

```

In bigger environments there is very useful pattern - [Cluster, which is great to architecting for scale](https://www.jenkins.io/doc/book/architecting-for-scale/).

Another important topic regardin Jenkins there is [Multibranch Pipeline](https://www.jenkins.io/doc/book/pipeline/multibranch/).

## Gitlab

There are many ways to install GitLab, but the simplest one is that [using Docker](https://docs.gitlab.com/omnibus/docker/). In this scenario we need to do following commands:

```bash
docker volume create gitlab-data
docker volume create gitlab-config
docker volume create gitlab-logs

docker run --detach \
  --hostname devops \
  --publish 443:443 --publish 80:80 --publish 2022:22 \
  --name gitlab \
  --restart always \
  --volume gitlab-config:/etc/gitlab \
  --volume gitlab-logs:/var/log/gitlab \
  --volume gitlab-data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
```
Another important topic is [GitLab Container Registry](https://docs.gitlab.com/omnibus/architecture/registry/README.html) for storing Docker images.

## Other CI/CD

* [GitHub Actions](https://github.com/features/actions)
* [Circle CI](https://circleci.com/)

## Ansible 

## Robot Framework

## JFrog Artifactory 

## Terraform

## Vault

## Consul

## Pact

## KVM

## Summary