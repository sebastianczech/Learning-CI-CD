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

To work it properly, is was using [insecure registry](https://docs.docker.com/registry/insecure/) and then [with self-signed certificate](https://hackernoon.com/create-a-private-local-docker-registry-5c79ce912620).

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

[Tutorial about creating swarm and deploy service](https://docs.docker.com/engine/swarm/swarm-tutoria):

```bash
docker info 
docker swarm init --advertise-addr 192.168.0.27

docker swarm join-token worker
docker swarm join --token SWMTKN-1-3hnvuy1bwvcrq398b616t1waaapzh0vgwvaxt048nktjb98470-3x2ejgu5jqjbtojib8t1i702y 192.168.0.27:2377

docker node ls

docker service create --replicas 1 --name helloworld alpine ping docker.com
docker service ls
docker service inspect --pretty helloworld
docker service ps helloworld
docker service scale helloworld=2
docker service rm helloworld

docker service create \
  --name api-java \
  --publish published=36080,target=48080 \
  --replicas 2 \
  192.168.0.27/api-java:cicd
docker service rm api-java
```

While creating pipeline to deploy on Docker Swarm using Ansible, I used module [docker_swarm_service](https://docs.ansible.com/ansible/latest/modules/docker_swarm_service_module.html).

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
kubectl apply -f .
```

For lab only I created [private registry for k3s](https://rancher.com/docs/k3s/latest/en/installation/private-registry/) in file ``/etc/rancher/k3s/registries.yaml``:

```
mirrors:
  docker.io:
    endpoint:
      - "http://192.168.0.18:5000"
```

To check pod and restart deployment, we can use commands from [K8s Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/):

```
kubectl describe pods api-java-deployment-75bb8f97df-gfss4    

kubectl delete -f deployment.yml
kubectl delete -f service.yml 
kubectl delete -f .
```

While integrating with Kubernetes, [problem with managing certficates need to resolved](https://kubernetes.io/docs/concepts/cluster-administration/certificates/).

While creating deployment and service, I used [tutorial about exposing external IP](https://kubernetes.io/docs/tutorials/stateless-application/expose-external-ip-address/).

To access IP from outside, I have changed iptables [using Oracle documentation](https://docs.oracle.com/en/operating-systems/oracle-linux/kubernetes/kube_admin_config_iptables.html):

```bash
sudo iptables -L -v -n    
sudo iptables-legacy -L -v -n      

sudo iptables-save > /home/seba/iptables-20200904                
sudo iptables-legacy-save > /home/seba/iptables-legacy-20200904  

sudo iptables -P FORWARD ACCEPT                
# or 
sudo iptables -F                                                 
sudo iptables -X                                                 
```

After that I found great article, which gives me more ideas what to do with Kubernetes and Ansible: [How useful is Ansible in a Cloud-Native Kubernetes Environment?](https://www.ansible.com/blog/how-useful-is-ansible-in-a-cloud-native-kubernetes-environment).

``TODO - check stateful set``

``TODO - check persistent volume``

``TODO - check config map``

``TODO - check secrets``

``TODO - check policies and network``

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

Sometimes there is no need to use Docker, but [global tools defined in Jenkins](https://www.jenkins.io/doc/book/pipeline/syntax/#tools).

While developing pipelines, I used [Jenkins Pipeline Linter Connector](https://marketplace.visualstudio.com/items?itemName=janjoerke.jenkins-pipeline-linter-connector), for which we need to use linter described in [pipeline development tools](https://www.jenkins.io/doc/book/pipeline/development/).

To use linter from command line, use:

```bash
export JENKINS_URL=devops:8080                                        
curl -Lv http://$JENKINS_URL/login 2>&1 | grep -i 'x-ssh-endpoint'  
< X-SSH-Endpoint: devops:7788  
ssh -l admin -p 7788 devops help 

export JENKINS_SSHD_PORT=7788
export JENKINS_HOSTNAME=devops
export JENKINS_USER=admin
ssh -l $JENKINS_USER -p $JENKINS_SSHD_PORT $JENKINS_HOSTNAME declarative-linter < Jenkinsfile

export JENKINS_URL=http://admin:***@devops:8080/ 
JENKINS_CRUMB=`curl "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)"`
curl -X POST -H $JENKINS_CRUMB -F "jenkinsfile=<Jenkinsfile" $JENKINS_URL/pipeline-model-converter/validate
```

In Visual Studio Code besides user and password I configured:
* Crumb URL: ```http://devops:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)```
* Linter URL: ```http://devops:8080/pipeline-model-converter/validate```

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
* [Getting started with GitLab CI/CD](https://gitlab.com/help/ci/quick_start/README)
* [GitLab pipelines](https://docs.gitlab.com/ee/ci/pipelines/)
* [GitLab Package Registry](https://gitlab.com/help/user/packages/package_registry/index)
* [Building Docker images with GitLab CI/CD](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html)
* [GitLab Container Registry](https://docs.gitlab.com/omnibus/architecture/registry/README.html) for storing Docker images.
* [GitLab Runner](https://docs.gitlab.com/runner/install/)

Using container registry from command line:

```bash
docker login registry.gitlab.com
docker build -t registry.gitlab.com/sebastianczech/simple-rest-api-java-spring .
docker image tag 192.168.0.27/api-java:cicd registry.gitlab.com/sebastianczech/simple-rest-api-java-spring
docker push registry.gitlab.com/sebastianczech/simple-rest-api-java-spring
docker logout
```

``TODO - build self-hosted container registry and push images from CI/CD to registry``

``TODO - create self-hosted runner and connect with self-hosted gitlab``

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

``TODO - try terraform with heroku``

## KVM

``TODO - try to run simple machine``

## SSL/TLS

Resources about SSL/TLS and certificates:
* [OpenSSL Cookbook](https://www.feistyduck.com/books/openssl-cookbook/)
* [openssl s_client](https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html)
* [certbot](https://certbot.eff.org/)
* [KeyStore Explorer](https://keystore-explorer.org/)
* [Keystore vs. Truststore](https://www.educative.io/edpresso/keystore-vs-truststore)

Creating own certificate:

```bash
sudo vi /etc/ssl/openssl.cnf  
# in the section [ v3_ca ]
subjectAltName=IP:192.168.0.27

mkdir -p certs

openssl req \
  -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key \
  -x509 -days 365 -out certs/domain.crt
# CN = 192.168.0.27

openssl x509  -noout -text -in certs/domain.crt 
```

Command use while learning from book [OpenSSL Cookbook](https://www.feistyduck.com/library/openssl-cookbook/online/ch-openssl.html):

### Getting started

```bash
openssl version
openssl version -a
openssl help
man ciphers
```

### Trust Store

Perl:
```bash
https://hg.mozilla.org/mozilla-central/raw-file/tip/security/nss/lib/ckfw/builtins/certdata.txt
https://raw.github.com/bagder/curl/master/lib/mk-ca-bundle.pl
```

Go:
```bash
https://github.com/agl/extract-nss-root-certs
wget https://raw.github.com/agl/extract-nss-root-certs/master/convert_mozilla_certdata.go
wget https://hg.mozilla.org/mozilla-central/raw-file/tip/security/nss/lib/ckfw/builtins/certdata.txt --output-document certdata.txt
go run convert_mozilla_certdata.go > ca-certificates
```

### Key and Certificate Management

1. Generate a strong private key,
2. Create a Certificate Signing Request (CSR) and send it to a CA,
3. Install the CA-provided certificate in your web server.

### Key generation

```bash
openssl genrsa -aes128 -out fd.key 2048
openssl rsa -text -in fd.key
openssl rsa -in fd.key -pubout -out fd-public.key
```

### Creating Certificate Signing Requests

```bash
openssl req -new -key fd.key -out fd.csr
openssl req -text -in fd.csr -noout
```

### Creating Certificate Signing Requests from existing certificate

```
openssl x509 -x509toreq -in fd.crt -out fd.csr -signkey fd.key
```

### Unattended CSR Generation

```bash
more fd.cnf

[req]
prompt = no
distinguished_name = dn
req_extensions = ext
input_password = PASSPHRASE

[dn]
CN = www.feistyduck.com
emailAddress = webmaster@feistyduck.com
O = Feisty Duck Ltd
L = London
C = GB

[ext]
subjectAltName = DNS:www.feistyduck.com,DNS:feistyduck.com

openssl req -new -config fd.cnf -key fd.key -out fd.csr
```

### Signing Your Own Certificates

```bash
openssl x509 -req -days 365 -in fd.csr -signkey fd.key -out fd.crt
```

### Creating Certificates Valid for Multiple Hostnames

```bash
more fd.ext

subjectAltName = DNS:*.feistyduck.com, DNS:feistyduck.com

openssl x509 -req -days 365 \
-in fd.csr -signkey fd.key -out fd.crt \
-extfile fd.ext
```

### Examining Certificates

```bash
openssl x509 -text -in fd.crt -noout
```

### PEM and DER Conversion

```bash
openssl x509 -inform PEM -in fd.pem -outform DER -out fd.der
openssl x509 -inform DER -in fd.der -outform PEM -out fd.pem
```

### PKCS#12 (PFX) Conversion

```bash
openssl pkcs12 -export \
    -name "My Certificate" \
    -out fd.p12 \
    -inkey fd.key \
    -in fd.crt \
    -certfile fd-chain.crt

openssl pkcs12 -in fd.p12 -out fd.pem -nodes

openssl pkcs12 -in fd.p12 -nocerts -out fd.key -nodes
openssl pkcs12 -in fd.p12 -nokeys -clcerts -out fd.crt
openssl pkcs12 -in fd.p12 -nokeys -cacerts -out fd-chain.crt
```

### Obtaining the List of Supported Suites

```bash
openssl ciphers -v 'ALL:COMPLEMENTOFALL'
```

### Performance

```bash
openssl speed rc4 aes rsa ecdh sha
```

### Connecting to SSL Services

```
openssl s_client -connect www.google.com:443
```

## cURL

* [SSL Certificate Verification](https://curl.haxx.se/docs/sslcerts.html)
* [How to curl an endpoint protected by mutual tls (mtls)](https://downey.io/notes/dev/curl-using-mutual-tls/)
* [Using Mutual TLS on the Client Side with Curl](https://smallstep.com/hello-mtls/doc/client/curl)
  
```bash
curl --cacert ca.crt \
     --key client.key \
     --cert client.crt \
     https://domain.com
```

## OCSP (Online Certificate Status Protocol)

Resources about OCSP:
* [What Is Online Certificate Status Protocol (OCSP) and Tutorial with Examples?](https://www.poftut.com/what-is-online-certificate-status-protocol-ocsp-and-tutorial-with-examples/)
* [Understanding Online Certificate Status Protocol and Certificate Revocation Lists](https://www.juniper.net/documentation/en_US/junos/topics/concept/certificate-ocsp-understanding.html)
* [OCSP Stapling](https://www.keycdn.com/support/ocsp-stapling)
* [OpenSSL OCSP](https://www.openssl.org/docs/man1.1.0/man1/ocsp.html)
* [OCSP Validation with OpenSSL](https://akshayranganath.github.io/OCSP-Validation-With-Openssl/)
* [Create your own OCSP server](https://medium.com/@bhashineen/create-your-own-ocsp-server-ffb212df8e63)

Testing OCSP with OpenSSL:

```bash
# Step 1: Get the server certificate
openssl s_client -connect www.akamai.com:443 < /dev/null 2>&1 |  sed -n '/-----BEGIN/,/-----END/p' > certificate.pem

# Step 2: Get the intermediate certificate
openssl s_client -showcerts -connect www.akamai.com:443 < /dev/null 2>&1 |  sed -n '/-----BEGIN/,/-----END/p'
openssl s_client -showcerts -connect www.akamai.com:443 < /dev/null 2>&1 |  sed -n '/-----BEGIN/,/-----END/p' > chain.pem        

# Step 3: Get the OCSP responder for server certificate
openssl x509 -noout -ocsp_uri -in certificate.pem 
openssl x509 -text -noout -in certificate.pem 

# Step 4: Make the OCSP request
openssl ocsp -issuer chain.pem -cert certificate.pem -text -url http://ocsp.digicert.com
openssl ocsp -issuer chain.pem -cert certificate.pem -text -url http://ocsp2.globalsign.com/cloudsslsha2g3 -header "HOST" "ocsp2.globalsign.com"
```

## Summary

After finishing work we can stop all container using command:

```bash
docker stop $(docker ps -a -q)
```