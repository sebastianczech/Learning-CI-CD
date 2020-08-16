# Learning CI/CD

Notes, configuration files and scripts created while learning Docker, Kubernetes, Jenkins, Gitlab, Ansible, Terraform and KVM.

## Docker 

## Docker Compose

## Kubernetes

## Docker Swarm

## Jenkins

### Installation

#### [In Docker](https://www.jenkins.io/doc/book/installing/#downloading-and-running-jenkins-in-docker)

```bash
docker network create jenkins
docker network ls

docker volume create jenkins-docker-certs\ndocker volume create jenkins-data
docker volume ls

docker container run --name jenkins-docker --rm --detach --privileged --network jenkins --network-alias docker --env DOCKER_TLS_CERTDIR=/certs --volume jenkins-docker-certs:/certs/client --volume jenkins-data:/var/jenkins_home --publish 2376:2376 docker:dind
docker container run --name jenkins-blueocean --rm --detach --network jenkins --env DOCKER_HOST=tcp://docker:2376 --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 --publish 8080:8080 --publish 50000:50000 --volume jenkins-data:/var/jenkins_home --volume jenkins-docker-certs:/certs/client:ro jenkinsci/blueocean

docker volume inspect jenkins-data 
sudo cat /var/lib/docker/volumes/jenkins-data/_data/secrets/initialAdminPassword 

```

#### [Cluster - architecting for scale](https://www.jenkins.io/doc/book/architecting-for-scale/)

## Gitlab

## Ansible 

## Terraform

## KVM