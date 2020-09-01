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

For storing Docker images you can use Docker Hub or [reploy a registry server](https://docs.docker.com/registry/deploying/). After starting it use commands to store images in new registry:

```bash
docker image tag sebastian-czech/simple-rest-api-python-flask  192.168.0.18:5000/python-api
docker push 192.168.0.18:5000/python-api

docker image tag sebastian-czech/simple-rest-api-java-spring  192.168.0.18:5000/java-api
docker push 192.168.0.18:5000/java-api
```

To work it properly, is was using [insecure registry](https://docs.docker.com/registry/insecure/).

To display all images you can use URLs:

```
http://192.168.0.18:5000/v2/_catalog
http://192.168.0.18:5000/v2/api-java/tags/list
```

## Docker Compose

To start Docker Compose from pipeline I used [Docker Compose Build Step Plugin](https://www.jenkins.io/doc/pipeline/steps/docker-compose-build-step/).

From CLI to start and stop server defined in compose file we should commands:

```bash
docker-compose up -d
docker-compose start    
docker-compose stop
docker-compose start webapp    
docker-compose stop webapp
docker-compose down
```

## Docker Swarm

``TODO - deploy app in swarm``

## Kubernetes

For learning there is a great Kubernetes - [K3s](https://k3s.io/). To use [``kubectl``](https://rancher.com/learning-paths/how-to-manage-kubernetes-with-kubectl/) I used following commands to configure it:

```bash
# mkdir /home/seba/.kube
# cp /etc/rancher/k3s/k3s.yaml /home/seba/.kube/config
# chown -R seba:seba /home/seba/.kube
$ export KUBECONFIG=/home/seba/.kube/config
```

Using following commands we can check default configuration:

```bash
➜  ~ kubectl get pods --all-namespaces 
NAMESPACE     NAME                                     READY   STATUS      RESTARTS   AGE
kube-system   helm-install-traefik-r46s6               0/1     Completed   0          11d
kube-system   metrics-server-7566d596c8-mx6bk          1/1     Running     22         11d
kube-system   local-path-provisioner-6d59f47c7-t8266   1/1     Running     42         11d
kube-system   svclb-traefik-vtcb6                      2/2     Running     44         11d
kube-system   coredns-8655855d6-nppnc                  1/1     Running     24         11d
kube-system   traefik-758cd5fc85-vhgzb                 1/1     Running     33         11d

➜  ~ kubectl cluster-info 
Kubernetes master is running at https://127.0.0.1:6443
CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

➜  ~ kubectl get nodes -o wide
NAME     STATUS   ROLES    AGE   VERSION        INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION    CONTAINER-RUNTIME
devops   Ready    master   11d   v1.18.6+k3s1   192.168.0.18   <none>        Debian GNU/Linux 10 (buster)   4.19.0-10-amd64   containerd://1.3.3-k3s2

➜  ~ kubectl get namespaces   
NAME              STATUS   AGE
default           Active   11d
kube-system       Active   11d
kube-public       Active   11d
kube-node-lease   Active   11d

➜  ~ kubectl get all --all-namespaces                                                                                      
NAMESPACE     NAME                                         READY   STATUS      RESTARTS   AGE
kube-system   pod/helm-install-traefik-r46s6               0/1     Completed   0          11d
kube-system   pod/metrics-server-7566d596c8-mx6bk          1/1     Running     22         11d
kube-system   pod/local-path-provisioner-6d59f47c7-t8266   1/1     Running     42         11d
kube-system   pod/svclb-traefik-vtcb6                      2/2     Running     44         11d
kube-system   pod/coredns-8655855d6-nppnc                  1/1     Running     24         11d
kube-system   pod/traefik-758cd5fc85-vhgzb                 1/1     Running     33         11d

NAMESPACE     NAME                         TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                      AGE
default       service/kubernetes           ClusterIP      10.43.0.1       <none>         443/TCP                      11d
kube-system   service/kube-dns             ClusterIP      10.43.0.10      <none>         53/UDP,53/TCP,9153/TCP       11d
kube-system   service/metrics-server       ClusterIP      10.43.163.21    <none>         443/TCP                      11d
kube-system   service/traefik-prometheus   ClusterIP      10.43.177.118   <none>         9100/TCP                     11d
kube-system   service/traefik              LoadBalancer   10.43.101.73    192.168.0.18   80:31584/TCP,443:32753/TCP   11d

NAMESPACE     NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
kube-system   daemonset.apps/svclb-traefik   1         1         1       1            1           <none>          11d

NAMESPACE     NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/metrics-server           1/1     1            1           11d
kube-system   deployment.apps/local-path-provisioner   1/1     1            1           11d
kube-system   deployment.apps/coredns                  1/1     1            1           11d
kube-system   deployment.apps/traefik                  1/1     1            1           11d

NAMESPACE     NAME                                               DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/metrics-server-7566d596c8          1         1         1       11d
kube-system   replicaset.apps/local-path-provisioner-6d59f47c7   1         1         1       11d
kube-system   replicaset.apps/coredns-8655855d6                  1         1         1       11d
kube-system   replicaset.apps/traefik-758cd5fc85                 1         1         1       11d

NAMESPACE     NAME                             COMPLETIONS   DURATION   AGE
kube-system   job.batch/helm-install-traefik   1/1           36s        11d
```

While preparing pipeline to deploy app in K8s, I used [blog post about CI/CD and K8s](https://www.magalix.com/blog/create-a-ci/cd-pipeline-with-kubernetes-and-jenkins) and [tutorial in which GKE was used](https://docs.bitnami.com/tutorials/create-ci-cd-pipeline-jenkins-gke/).

To integrate Ansible with K8s I used [module k8s](https://docs.ansible.com/ansible/latest/modules/k8s_module.html) and [k8s_info](https://docs.ansible.com/ansible/latest/modules/k8s_info_module.html).

For deployment and service from command line we can use commands:

```bash
kubectl apply -f deployment.yml
kubectl apply -f service.yml
```

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

In bigger environments there is very useful pattern - [Cluster, which is great to architecting for scale](https://www.jenkins.io/doc/book/architecting-for-scale/). Another great tutorial - [building master and slave](https://dzone.com/articles/jenkins-03-configure-master-and-slave).

Another important topics:
* [Multibranch Pipeline](https://www.jenkins.io/doc/book/pipeline/multibranch/)
* [Distributed Builds](https://wiki.jenkins.io/display/JENKINS/Distributed+builds)
* [Build a Java app with Maven](https://www.jenkins.io/doc/tutorials/build-a-java-app-with-maven/)
* [Build a Python app with PyInstaller](https://www.jenkins.io/doc/tutorials/build-a-python-app-with-pyinstaller/)
* [Pipeline syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
* [Managing tools](https://www.jenkins.io/doc/book/managing/tools/)
* [Input parameters](https://www.jenkins.io/doc/pipeline/steps/pipeline-input-step/)
* [Build user](https://www.jenkins.io/doc/pipeline/steps/build-user-vars-plugin/)
* [Mulit-configuration project](https://www.theserverside.com/video/How-to-use-the-Jenkins-multi-configuration-project)
* [Using Docker with Pipeline](https://www.jenkins.io/doc/book/pipeline/docker/)
* [Docker Pipeline plugin](https://docs.cloudbees.com/docs/admin-resources/latest/plugins/docker-workflow)

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

``TODO - on 1 jenkins install some tools``

``TODO - try advanced pipelines and use plugins for IDE``

To abort job, which cannot be stopped from UI, we can usi Manage *Jenkins -> Script Console*:

```java
Jenkins.instance.getItemByFullName("CI-CD-pipeline-analyze-code")
  .getBuildByNumber(1)
  .finish(
          hudson.model.Result.ABORTED,
          new java.io.IOException("Aborting build")
  );
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
* [GitLab pipelines](https://docs.gitlab.com/ee/ci/pipelines/)

``TODO - build container registry``

``TODO - build gitlab pipelines``

## Other CI/CD

* [GitHub Actions](https://github.com/features/actions)
* [TeamCity](https://www.jetbrains.com/teamcity/)
* [Circle CI](https://circleci.com/)
* [Travis CI](https://travis-ci.org/)

## Ansible 

For preparing each component of CI/CD environment, I created many playbooks. 

Besides typical playbooks there are other important topics to learn:
* [variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)
* [handlers](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html#handlers-running-operations-on-change)
* [templates](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html)
* [developing modules](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html)
* [vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html)

## Robot Framework

[To install Robot Framework, I used Docker](https://hub.docker.com/r/robotframework/rfdocker). To integrate it with Jenkins, [there is needed additional plugin](https://plugins.jenkins.io/robot/). After tests are finished, [results should be published to Jenkins](https://www.jenkins.io/doc/pipeline/steps/robot/).

## SonarQube

[To install SonarQube, I used Docker](https://docs.sonarqube.org/latest/setup/install-server/). To integrate it with Jenkins, [there is needed additional plugin](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-jenkins/). For Sonar Quality Gate it's important to configure web hook in project settings e.g. ``jenkins	http://192.168.0.18:8080/sonarqube-webhook/``.

## JFrog Artifactory 

[To install Artifactory, I used Docker](https://www.jfrog.com/confluence/display/JFROG/Installing+Artifactory#InstallingArtifactory-DockerInstallation). To start working with Artifactory, it's good to read examples [Jenkins Pipeline - Working With Artifactory](https://github.com/jfrog/project-examples/tree/master/jenkins-examples/pipeline-examples) and tutorials:
* [Configuring Jenkins Artifactory Plug-in](https://www.jfrog.com/confluence/display/JFROG/Configuring+Jenkins+Artifactory+Plug-in)
* [Working With Pipeline Jobs in Jenkins](https://www.jfrog.com/confluence/display/JFROG/Working+With+Pipeline+Jobs+in+Jenkins)

## Sonatype Nexus

[To install Nexus, I used Docker](https://hub.docker.com/r/sonatype/nexus3/). After that I started to integrate it with Jenkins [using tutorial about publishing Maven artifacts to Nexus](https://dzone.com/articles/jenkins-publish-maven-artifacts-to-nexus-oss-using). While talking about artifacts and version, it's worth to read [about Maven snapshot](https://stackoverflow.com/questions/5901378/what-exactly-is-a-maven-snapshot-and-why-do-we-need-it).

## Terraform

``TODO - try terraform``

## Vault

``TODO - try vault``

## Consul

``TODO - try service discovery``

## Pact

``TODO - try contract testing with pact``

## KVM

``TODO - try to run simple machine``

## Summary

After finishing work we can stop all container using command:

```bash
docker stop $(docker ps -a -q)
```