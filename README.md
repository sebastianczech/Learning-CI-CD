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

While containerizing app, important topic is [improve performance e.g. for Spring](https://spring.io/guides/gs/spring-boot-docker/)

## Docker Registry

For storing Docker images you can use Docker Hub or [reploy a registry server](https://docs.docker.com/registry/deploying/).

## Docker Compose

## Docker Swarm

## Kubernetes

For learning there is a great Kubernetes - [K3s](https://k3s.io/).

## Jenkins

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

Another important topics:
* [Multibranch Pipeline](https://www.jenkins.io/doc/book/pipeline/multibranch/)
* [Distributed Builds](https://wiki.jenkins.io/display/JENKINS/Distributed+builds)
* [Build a Java app with Maven](https://www.jenkins.io/doc/tutorials/build-a-java-app-with-maven/)

Define new Pipeline from SCM e.g.:
```
http://192.168.0.18:9080/seba/simple-rest-api-java-spring
```

Create API token for user in Jenkins and configure build trigger for pipeline in Jenkins configured as web hook in GitLab:
```
http://admin:USER_TOKEN@192.168.0.18:8080/job/API-java/build?token=PIPELINE_TOKEN
```

To debug remote trigger for pipeline, you can use:
```
curl -u admin:USER_TOKEN "http://192.168.0.18:8080/job/API-java/build?token=PIPELINE_TOKEN"
```

If you have error *Url is blocked: Requests to the local network are not allowed*, then allow in GitLab in Admin Area settings:
```
http://192.168.0.18:9080/admin/application_settings/network
```

## Gitlab

There are many ways to install GitLab, but the simplest one is that [using Docker](https://docs.gitlab.com/omnibus/docker/). In this scenario we need to do following commands:

```bash
docker volume create gitlab-data
docker volume create gitlab-config
docker volume create gitlab-logs

docker run --detach \
  --hostname devops \
  --publish 9443:443 --publish 9080:80 --publish 2022:22 \
  --name gitlab \
  --restart always \
  --volume gitlab-config:/etc/gitlab \
  --volume gitlab-logs:/var/log/gitlab \
  --volume gitlab-data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
```

Another important topics:
* [Configuring the external URL for GitLab](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-the-external-url-for-gitlab)
* [GitLab Container Registry](https://docs.gitlab.com/omnibus/architecture/registry/README.html) for storing Docker images.

## Other CI/CD

* [GitHub Actions](https://github.com/features/actions)
* [Circle CI](https://circleci.com/)

## Ansible 

For preparing each component of CI/CD environment, I created many playbooks. 

Besides typical playbooks there are other important topics to learn:
* [variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)
* [handlers](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html#handlers-running-operations-on-change)
* [templates](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html)
* [developing modules](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html)
* [vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html)

## Robot Framework

[To install Robot Framework, I used Docker](https://hub.docker.com/r/robotframework/rfdocker)

## SonarQube

[To install SonarQube, I used Docker](https://docs.sonarqube.org/latest/setup/install-server/)

## JFrog Artifactory 

[To install Artifactory, I used Docker](https://www.jfrog.com/confluence/display/JFROG/Installing+Artifactory#InstallingArtifactory-DockerInstallation).

## Sonatype Nexus

[To install Nexus, I used Docker](https://hub.docker.com/r/sonatype/nexus3/).

## Terraform

## Vault

## Consul

## Pact

## KVM

## Summary

After finishing work we can stop all container using command:

```bash
docker stop $(docker ps -a -q)
```