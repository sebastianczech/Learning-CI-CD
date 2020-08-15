# Learning CI/CD

Notes, configuration files and scripts created while learning Docker, Kubernetes, Jenkins, Gitlab, Ansible, Terraform and KVM.

## Docker 

## Kubernetes

## Jenkins

### Installation

#### [In Docker](https://www.jenkins.io/doc/book/installing/#downloading-and-running-jenkins-in-docker)

```bash
docker network create jenkins
docker network ls

docker volume create jenkins-docker-certs\ndocker volume create jenkins-data
docker volume ls

docker container run \\n  --name jenkins-docker \\n  --rm \\n  --detach \\n  --privileged \\n  --network jenkins \\n  --network-alias docker \\n  --env DOCKER_TLS_CERTDIR=/certs \\n  --volume jenkins-docker-certs:/certs/client \\n  --volume jenkins-data:/var/jenkins_home \\n  --publish 2376:2376 \\n  docker:dind
docker container run \\n  --name jenkins-blueocean \\n  --rm \\n  --detach \\n  --network jenkins \\n  --env DOCKER_HOST=tcp://docker:2376 \\n  --env DOCKER_CERT_PATH=/certs/client \\n  --env DOCKER_TLS_VERIFY=1 \\n  --publish 8080:8080 \\n  --publish 50000:50000 \\n  --volume jenkins-data:/var/jenkins_home \\n  --volume jenkins-docker-certs:/certs/client:ro \\n  jenkinsci/blueocean

docker volume inspect jenkins-data 
sudo cat /var/lib/docker/volumes/jenkins-data/_data/secrets/initialAdminPassword 

```

## Gitlab

## Ansible 

## Terraform

## KVM