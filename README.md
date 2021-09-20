# Learning CI/CD

Repository contains notes, configuration files and scripts created while learning Docker, Kubernetes, Jenkins, Gitlab, Ansible, Terraform and KVM.

## Overview

[Solution proposal](https://app.lucidchart.com/documents/edit/bf943422-2c36-4820-9963-7439bd7eb89f) contains key technologies used for creating CI/CD in home environment. Details of my solution are available on [solution overview](diagrams/solution_overview.puml), which I presented below. It was created using plantUML, but there are also alternatives such as a [diagram as a code](https://diagrams.mingrammer.com/).

![solution_overview](diagrams/solution_overview.png "Solution overview")

## Prepare VM for CI/CD learning

At the beginning to prepare VM for learning [downloaded Debian non-free netinst version](https://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/10.5.0+nonfree/amd64/iso-cd/firmware-10.5.0-amd64-netinst.iso) and after creating VM in VirtualBox and installing Debian, on host add IP address of the machine and copy SSH keys to enable passwordless access:

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

While learning Docker some time ago, I have created gist with [many examples of useful commands](https://gist.github.com/sebastianczech/cc8f873b37b4fe286962af74ad79a294).

For installing Docker I used great [tutorial](https://www.rechberger.io/tutorial-install-docker-using-ansible-on-a-remote-server/), which I modiifed to use [Docker on Debian](https://docs.docker.com/engine/install/debian/). Besides Docker, I installed ``Docker Compose`` and ``Ctop``.

Besides creating single images for containers, in developing environment there is very useful pattern - [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/), which allow you aterfacts build in 1 container to be used on another one.

While containerizing app, important topic is [improve performance e.g. for Spring](https://spring.io/guides/gs/spring-boot-docker/)

## Docker Registry

For storing Docker images you can use Docker Hub or [deploy a registry server](https://docs.docker.com/registry/deploying/). After starting it use commands to store images in new registry:

```bash
docker image tag sebastian-czech/simple-rest-api-python-flask  192.168.0.18:5000/python-api
docker push 192.168.0.18:5000/python-api

docker image tag sebastian-czech/simple-rest-api-java-spring  192.168.0.18:5000/java-api
docker push 192.168.0.18:5000/java-api
```

At first I was using [insecure registry](https://docs.docker.com/registry/insecure/) and then [with self-signed certificate](https://hackernoon.com/create-a-private-local-docker-registry-5c79ce912620).

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

To start with Docker Swarm there is a [tutorial about creating swarm and deploy service](https://docs.docker.com/engine/swarm/swarm-tutoria). In my solution I used following commands:

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

While learning Kubernets some time ago, I have created gist with [many examples of useful commands](https://gist.github.com/sebastianczech/d3dc1852b93d993c20d12ad56c79bc51).

In another my repository [DevOps-Engineer](https://github.com/sebastianczech/DevOps-Engineer) I have included many commands for K8s.

For learning there is a great Kubernetes - [K3s](https://k3s.io/). To use [``kubectl``](https://rancher.com/learning-paths/how-to-manage-kubernetes-with-kubectl/) I used following commands to configure it:

```bash
# mkdir /home/seba/.kube
# cp /etc/rancher/k3s/k3s.yaml /home/seba/.kube/config
# chown -R seba:seba /home/seba/.kube
$ export KUBECONFIG=/home/seba/.kube/config
```

Using following commands we can check default configuration:

```bash
kubectl api-resources

kubectl get pods --all-namespaces 
NAMESPACE     NAME                                     READY   STATUS      RESTARTS   AGE
kube-system   helm-install-traefik-r46s6               0/1     Completed   0          11d
kube-system   metrics-server-7566d596c8-mx6bk          1/1     Running     22         11d
kube-system   local-path-provisioner-6d59f47c7-t8266   1/1     Running     42         11d
kube-system   svclb-traefik-vtcb6                      2/2     Running     44         11d
kube-system   coredns-8655855d6-nppnc                  1/1     Running     24         11d
kube-system   traefik-758cd5fc85-vhgzb                 1/1     Running     33         11d

kubectl cluster-info 
Kubernetes master is running at https://127.0.0.1:6443
CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

kubectl get nodes -o wide
NAME     STATUS   ROLES    AGE   VERSION        INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION    CONTAINER-RUNTIME
devops   Ready    master   11d   v1.18.6+k3s1   192.168.0.18   <none>        Debian GNU/Linux 10 (buster)   4.19.0-10-amd64   containerd://1.3.3-k3s2

kubectl get namespaces   
NAME              STATUS   AGE
default           Active   11d
kube-system       Active   11d
kube-public       Active   11d
kube-node-lease   Active   11d

kubectl get all --all-namespaces 
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

Using following commands you can nanually scale deployment:

```bash
kubectl scale deployment --replicas=2 api-java-deployment
```

Using following commands you can use config maps:

```
kubectl create configmap api-java-config --from-file=application.properties
kubectl describe configmaps api-java-config 
kubectl get configmaps 
kubectl get configmaps api-java-config
kubectl get configmaps api-java-config -o yaml
```

Using following commands you can use secrets:

```bash
echo -n 'secret123' | base64  

kubectl apply -f secret.yaml  
kubectl describe secret api-java-password   
kubectl get secrets   
kubectl get secret api-java-password -o jsonpath='{.data.password}' | base64 --decode 
```

Using following commands you can use creatie simple Ingress:

```bash
kubectl apply -f ingress.yml  
kubectl get ing --all-namespaces   
kubectl delete -f ingress.yml
```

After that simple Java API can be access via http://api-java.192.168.0.18.nip.io/.

To configure Traefik with dashboard I used [Deploying Traefik as Ingress Controller for Your Kubernetes Cluster](https://medium.com/kubernetes-tutorials/deploying-traefik-as-ingress-controller-for-your-kubernetes-cluster-b03a0672ae0c):

```bash
kubectl create -f traefik-webui-svc.yaml
kubectl describe svc traefik-web-ui --namespace=kube-system
kubectl create -f traefik-ingress.yaml
kubectl get ing --namespace=kube-system   
```

In another solution I used [K3S: Traefik Dashboard activation](https://forums.rancher.com/t/k3s-traefik-dashboard-activation/17142) and [Traefik - Helm chart](https://github.com/helm/charts/tree/master/stable/traefik#configuration):

```bash
sudo vi /var/lib/rancher/k3s/server/manifests/traefik.yaml

    dashboard:
        enabled: true
        domain: "dashboard-traefik.192.168.0.18.traefik.me"

sudo kubectl apply -f /var/lib/rancher/k3s/server/manifests/traefik.yaml 
```

After that Traefik dashboard can be access via http://dashboard-traefik.192.168.0.18.traefik.me/dashboard/.

Detailed information about Traefik can be found on [Connecting Users to Applications with Kubernetes Ingress Controllers](https://traefik.io/blog/connecting-users-to-applications-with-kubernetes-ingress-controllers/), [13 Key Considerations When Selecting an Ingress Controller for Kubernetes](https://traefik.io/blog/13-key-considerations-when-selecting-an-ingress-controller-for-kubernetes-d3e5d98ed8b7/) and [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/#additional-controllers).

With that subject there is connected point about wildcard DNS:
* [nip.io](https://nip.io/)
* [traefik.me](http://traefik.me/)

Another important topic is [Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) explained in [Kubernetes Operators Explained](https://blog.container-solutions.com/kubernetes-operators-explained). 

Next topic after that is [Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).

At the end I have created comparission between service mesh, ingress controller and API gateway.

### Service Mesh vs. Ingress Controller vs. API gateway

|  | **Service Mesh** | **Ingress Controller** | **API gateway** |
|-|-|-|-|
| Definition | [dedicated infrastructure layer for facilitating service-to-service communications between microservices, often using a sidecar proxy](https://en.wikipedia.org/wiki/Service_mesh) | [an API object that manages external access to the services in a cluster, typically HTTP](https://kubernetes.io/docs/concepts/services-networking/ingress/) | [takes all API calls from clients, then routes them to the appropriate microservice with request routing, composition, and protocol translation](https://www.nginx.com/learn/api-gateway/) |
| Example of product | [Istio](https://istio.io/) | [Traefik](https://containo.us/traefik/), [Envoy](https://www.envoyproxy.io/) | [KrakenD](https://www.krakend.io/), [Kong](https://konghq.com/kong/) |
| Key points | decorator, circuit breaker, traffic management, security, observability (tracing, metrics and logging ) | edge router, reverse proxy, auto service discovery, routing, load balancing, security, observability | business logic, monitoring, security, cache, throttling, aggregation, manipulation, proxy, filtering, QoS, decoding |

### Civo - k3s-powered Kubernetes service

* [Civo learn with our guides](civo.com/learn)
* [#Kube100](https://github.com/civo/kube100)
* [Civo Command-Line Client](https://github.com/civo/cli)
* [Civo Kubernetes Marketplace](https://github.com/civo/kubernetes-marketplace)

```bash
vi ~/.kube/config
kubectx k3s_cicd 
kubectl cluster-info
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" | jid
kubectl top pod --all-namespaces
kubectl apply -f kubernetes/civo/ingress-jenkins.yaml
kubectl get all --all-namespaces
export JENKINS_URL=http://jenkins.e596da70-1439-44e8-8ce9-dd0076eef9e9.k8s.civo.com

civo apikey add K3S_CICD ***
civo quota

civo kubernetes config k3s_cicd -s --merge
civo kubernetes ls 
civo kubernetes show k3s_cicd
civo kubernetes applications list
civo kubernetes scale k3s_cicd --nodes=3
civo kubernetes create --remove-applications=traefik --nodes=2 --wait
civo kubernetes rename k3s_cicd --name="k3s_cicd_new"
civo kubernetes applications add Longhorn --cluster=k3s_cicd
civo kubernetes recycle k3s_cicd --node kube-node-f0de 

civo firewall list
civo firewall rule ls k3s_cicd   

export DNS="e89c398e-afac-4f2e-908b-3716147cb1c8.k8s.civo.com" # As per dashboard
export OPENFAAS_URL=http://$DNS:31112
cat /tmp/passwd | faas-cli login --username admin --password-stdin
faas-cli store list
faas-cli list --verbose

faas-cli store deploy nodeinfo
faas-cli describe nodeinfo
echo | faas-cli invoke nodeinfo
echo -n "verbose" | faas-cli invoke nodeinfo

kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
kubectl top node
kubectl top pod --all-namespaces
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

After installing Jenkins define new Pipeline from SCM e.g.:
```
http://192.168.0.18:9080/seba/simple-rest-api-java-spring
```

Then create API token for user in Jenkins and configure build trigger for pipeline in Jenkins configured as web hook in GitLab:
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

### Jenkins and security

Articles connected with Jenkins and certificates:

* [Java Keytool](http://tutorials.jenkov.com/java-cryptography/keytool.html)
* [Add GitHub SSL Certificate to Jenkins Keystore](https://gist.github.com/shanedroid/20ab6f1b50ac9a2d8713c570c165e598)

Example of use ``keytool``:

```bash
keytool -genkeypair -keyalg RSA -alias self_singed -keypass test -keystore test.keystore.p12 -storepass test
keytool -importkeystore -scrkeystore test.keystore.p12 -destkeystore test2.keystore.p12 -deststoretype pkcs12
keytool -list -keystore /etc/pki/java/cacerts -storepass changeit
```

### Jenkins and high availability

Articles about HA in Jenkins:

* [A Jenkins Master, with a Jenkins Master, with a ...](https://endocode.com/blog/2018/08/17/jenkins-high-availability-setup/)
* [Architecting for Scale](https://www.jenkins.io/doc/book/scaling/architecting-for-scale/)
* [Architecting for Manageability](https://www.jenkins.io/doc/book/scaling/architecting-for-manageability/)
* [How to configure Jenkins with High Availability?](https://www.opcito.com/blogs/how-to-configure-jenkins-with-high-availability/)

### Jenkins and Helm

Using [Jenkins Helm Chart](https://github.com/jenkinsci/helm-charts) to install Jenkins:

```bash
brew install helm
helm repo list

helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm search repo stable

helm repo add jenkins https://charts.jenkins.io
helm search repo jenkins

helm show values jenkins/jenkins
helm install jenkins/jenkins -f kubernetes/jenkins/helm-jenkins.yaml --generate-name

NAME: jenkins-1602621398
LAST DEPLOYED: Tue Oct 13 22:36:41 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:
  printf $(kubectl get secret --namespace default jenkins-1602621398 -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/component=jenkins-master" -l "app.kubernetes.io/instance=jenkins-1602621398" -o jsonpath="{.items[0].metadata.name}")
  echo http://127.0.0.1:8080
  kubectl --namespace default port-forward $POD_NAME 28080:8080

3. Login with the password from step 1 and the username: admin

4. Use Jenkins Configuration as Code by specifying configScripts in your values.yaml file, see documentation: http:///configuration-as-code and examples: https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine
For more information about Jenkins Configuration as Code, visit:
https://jenkins.io/projects/jcasc/

helm list  
helm uninstall jenkins-1602621398           
```

### Jenskins on Kubernetes

Articles about K8s and Jenkins:

* [How to build CI/CD pipelines on Kubernetes](https://cloudowski.com/articles/how-to-build-cicd-pipelines-on-kubernetes-copy/)
* [Code - Jenkins on Kubernetes](https://github.com/lukefernandez/jenkins-on-kubernetes/tree/main/code-snippets)
* [Jenkins on Kubernetes: From Zero to Hero](https://medium.com/slalom-build/jenkins-on-kubernetes-4d8c3d9f2ece)
* [Kubernetes provider for Terraform (alpha)](https://github.com/hashicorp/terraform-provider-kubernetes-alpha)
* [Jenkins Configuration as Code](https://www.jenkins.io/projects/jcasc/)
* [Zero-downtime Deployment in Kubernetes with Jenkins](https://kubernetes.io/blog/2018/04/30/zero-downtime-deployment-kubernetes-jenkins/)
* [Jenkisn plugin - Kubernetes](https://plugins.jenkins.io/kubernetes/)
* [Jenkins plugin - OpenId Connect Auth](https://plugins.jenkins.io/oic-auth/)
* [Jenkins plugin - OpenId](https://plugins.jenkins.io/openid/)
* [Jenkins plugin - Simple theme](https://plugins.jenkins.io/simple-theme-plugin/)
* [Extending with Shared Libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)

### Jenkisn and performance optimization

* [Coding continuous delivery — performance optimization for the jenkins pipeline](https://cloudogu.com/en/blog/continuous_delivery_2)
* [Scaling Pipelines](https://www.jenkins.io/doc/book/pipeline/scaling-pipeline/)
* [Parallelizing Jenkins Pipelines](https://engineering.medallia.com/blog/posts/parallelizing-jenkins-pipelines/)
* [Parallelism and Distributed Builds with Jenkins](https://www.cloudbees.com/blog/parallelism-and-distributed-builds-jenkins)
* [Parallel stages with Declarative Pipeline](https://www.jenkins.io/blog/2017/09/25/declarative-1/)
* [Parallel syntax](https://www.jenkins.io/doc/book/pipeline/syntax/#parallel)

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

To register GitLab runner installed using Docker use following comman:
```bash
docker run --rm -it -v gitlab-runner-config:/etc/gitlab-runner gitlab/gitlab-runner:latest register
```

To use container registry from command line use followin commands:

```bash
docker login registry.gitlab.com
docker build -t registry.gitlab.com/sebastianczech/simple-rest-api-java-spring .
docker image tag 192.168.0.27/api-java:cicd registry.gitlab.com/sebastianczech/simple-rest-api-java-spring
docker push registry.gitlab.com/sebastianczech/simple-rest-api-java-spring
docker logout
```

## Other CI/CD

* [GitHub Actions](https://github.com/features/actions)
* [TeamCity](https://www.jetbrains.com/teamcity/)
* [Drone](https://www.drone.io/)
* [Spinnaker](https://spinnaker.io/)
* [Circle CI](https://circleci.com/)
* [Travis CI](https://travis-ci.org/)
* [Buddy](https://buddy.works/)
* [GoCD](https://www.gocd.org/)
* [Bamboo](https://www.atlassian.com/software/bamboo)
* [CodeShip](https://codeship.com/)
* [Buildbot](https://buildbot.net/)
* [Nevercode](https://nevercode.io/)
* [Concourse CI](https://concourse-ci.org/)
* [Jenkins X - Cloud Native CI/CD Built On Kubernetes](https://jenkins-x.io/)

## Ansible 

For preparing each component of CI/CD environment, I created many playbooks. 

Besides typical playbooks there are other important topics to learn:
* [variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)
* [handlers](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html#handlers-running-operations-on-change)
* [templates](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html)
* [developing modules](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html)
* [vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
* [roles](https://www.digitalocean.com/community/tutorials/how-to-use-ansible-roles-to-abstract-your-infrastructure-environment)

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

Interesting articles to start with Terraform:

* [Get started with Terraform Cloud](https://app.terraform.io/app/getting-started/intro)
* [Introduction to Infrastructure as Code with Terraform](https://learn.hashicorp.com/tutorials/terraform/infrastructure-as-code)
* [Get Started - Terraform Cloud](https://learn.hashicorp.com/collections/terraform/cloud-get-started)
* [Workspaces](https://www.terraform.io/docs/cloud/workspaces/index.html)
* [Workflows](https://www.terraform.io/docs/cloud/run/ui.html)
* [Terraform Cloud](https://app.terraform.io/app)
* [Using Terraform with Heroku](https://devcenter.heroku.com/articles/using-terraform-with-heroku)
* [Terraform Provider Heroku](https://github.com/heroku/terraform-provider-heroku)
* [Terraform Registry - Heroku Provider](https://registry.terraform.io/providers/heroku/heroku/latest/docs)

Example of using Terraform:

```bash
terraform login  

more example.tf 

terraform {
  backend "remote" {
    organization = "sebastianczech"

    workspaces {
      name = "Learning-Terraform"
    }
  }
}

terraform init 
terraform plan
terraform apply 
terraform apply -var-file="terraform.tfvars"                      
```

### Terraform provider for libvirt

* [Terraform provider for libvirt](https://github.com/dmacvicar/terraform-provider-libvirt)
* [How To Provision VMs on KVM with Terraform](https://computingforgeeks.com/how-to-provision-vms-on-kvm-with-terraform/)
* [How to use Terraform to create a small-scale Cloud Infrastructure](https://medium.com/terraform-how-to-create-a-smale-scale-cloud/instructions-on-how-to-use-terraform-to-create-a-small-scale-cloud-infrastructure-8c14cb8603a3)


```
git clone https://github.com/dmacvicar/terraform-provider-libvirt
cd terraform-provider-libvirt

sudo apt install libvirt-dev 
sudo apt install genisoimage
sudo cp /usr/bin/genisoimage /usr/local/bin/mkisofs   

make 
mkdir ~/.terraform.d/plugins/
cp terraform-provider-libvirt ~/.terraform.d/plugins/ 
mkdir -p ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64
cp terraform-provider-libvirt ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64/

mkdir -p /tmp/terraform-provider-libvirt-pool-ubuntu

sudo grep security_driver /etc/libvirt/qemu.conf
security_driver = "none"

sudo systemctl restart libvirtd.service

cd examples/v0.13/ubuntu
terraform init   
terraform plan
terraform apply -auto-approve
terraform destroy -auto-approve
```

```
cat ubuntu-example.tf
terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.2"
    }
  }
}

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "ubuntu" {
  name = "ubuntu"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-ubuntu"
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "ubuntu-qcow2" {
  name   = "ubuntu-qcow2"
  pool   = libvirt_pool.ubuntu.name
  source = "https://cloud-images.ubuntu.com/releases/xenial/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img"
  format = "qcow2"
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.ubuntu.name
}

# Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  name   = "ubuntu-terraform"
  memory = "512"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name = "default"
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# IPs: use wait_for_lease true or after creation use terraform refresh and terraform show for the ips of domain
```

### Terraform with Docker

[Instruction step by step](https://learn.hashicorp.com/tutorials/terraform/infrastructure-as-code?in=terraform/docker-get-started):

```
cd terraform/docker 
terraform init

terraform fmt
terraform validate

terraform plan
terraform apply
terraform apply -var "container_name=YetAnotherName"

terraform show
terraform state list
terraform output

docker ps
curl http://localhost:8000/

terraform destroy
```

### Terraform with localstack

Following commands were prepared after reading material about [Localstack with Terraform and Docker running AWS locally](https://dev.to/mrwormhole/localstack-with-terraform-and-docker-for-running-aws-locally-3a6d).

```
cd terraform/localstack
vi main.tf

terraform init
terraform plan
terraform apply --auto-approve

aws --endpoint-url=http://localhost:4566 dynamodb list-tables

aws dynamodb scan --endpoint-url http://localhost:4566 --table-name dogs

aws --endpoint-url=http://localhost:4566 s3 mb s3://demo-bucket
aws --endpoint-url=http://localhost:4566 s3api put-bucket-acl --bucket demo-bucket --acl public-read

aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 s3 ls s3://demo-bucket
```

#### Localstack

Start: 

```bash
pip install --upgrade localstack
localstack start
SERVICES=s3 KINESIS_PROVIDER=kinesalite localstack --debug start
```

or:

```bash
docker run --rm -it -p 4566:4566 -p 4571:4571 --env SERVICES=s3 --env KINESIS_PROVIDER=kinesalite --name localstack localstack/localstack
```

or:

```bash
cd terraform/localstack
docker-compose up
```

Check status:

```bash
curl http://127.0.0.1:4566/health | jq
```

#### Localstack problem with DynamoDB

```
docker exec -it localstack_main bash

bash-5.0# cd /opt/code/localstack/localstack/infra/dynamodb

bash-5.0# java -Djava.library.path=./DynamoDBLocal_lib -Xmx256m -jar DynamoDBLocal.jar -port 53703 -inMemory
Initializing DynamoDB Local with the following configuration:
Port:   53703
InMemory:       true
DbPath: null
SharedDb:       false
shouldDelayTransientStatuses:   false
CorsParams:     *

Exception in thread "main" java.lang.ExceptionInInitializerError
        at org.eclipse.jetty.http.MimeTypes.<clinit>(MimeTypes.java:191)
        at org.eclipse.jetty.server.handler.ContextHandler.doStart(ContextHandler.java:836)
        at org.eclipse.jetty.util.component.AbstractLifeCycle.start(AbstractLifeCycle.java:68)
        at org.eclipse.jetty.util.component.ContainerLifeCycle.start(ContainerLifeCycle.java:167)
        at org.eclipse.jetty.util.component.ContainerLifeCycle.doStart(ContainerLifeCycle.java:119)
        at org.eclipse.jetty.server.handler.AbstractHandler.doStart(AbstractHandler.java:113)
        at org.eclipse.jetty.util.component.AbstractLifeCycle.start(AbstractLifeCycle.java:68)
        at org.eclipse.jetty.util.component.ContainerLifeCycle.start(ContainerLifeCycle.java:167)
        at org.eclipse.jetty.server.Server.start(Server.java:418)
        at org.eclipse.jetty.util.component.ContainerLifeCycle.doStart(ContainerLifeCycle.java:110)
        at org.eclipse.jetty.server.handler.AbstractHandler.doStart(AbstractHandler.java:113)
        at org.eclipse.jetty.server.Server.doStart(Server.java:382)
        at org.eclipse.jetty.util.component.AbstractLifeCycle.start(AbstractLifeCycle.java:68)
        at com.amazonaws.services.dynamodbv2.local.server.DynamoDBProxyServer.start(DynamoDBProxyServer.java:83)
        at com.amazonaws.services.dynamodbv2.local.main.ServerRunner.main(ServerRunner.java:76)
Caused by: java.nio.charset.IllegalCharsetNameException: l;charset=iso-8859-1
        at java.base/java.nio.charset.Charset.checkName(Unknown Source)
        at java.base/java.nio.charset.Charset.lookup2(Unknown Source)
        at java.base/java.nio.charset.Charset.lookup(Unknown Source)
        at java.base/java.nio.charset.Charset.forName(Unknown Source)
        at org.eclipse.jetty.http.MimeTypes$Type.<init>(MimeTypes.java:113)
        at org.eclipse.jetty.http.MimeTypes$Type.<clinit>(MimeTypes.java:69)
        ... 15 more

bash-5.0# mkdir JAR
bash-5.0# cd JAR/
bash-5.0# wget https://github.com/intoolswetrust/jd-cli/releases/download/jd-cli-1.2.0/jd-cli-1.2.0-dist.tar.gz
bash-5.0# java -jar jd-cli.jar ../com/amazonaws/services/dynamodbv2/local/main/ServerRunner.class 
```

#### AWS CLI

[AWS CLI](https://aws.amazon.com/cli/) can be used to access Localstack:

```bash
aws configure --profile default

AWS Access Key ID [None]: test
AWS Secret Access Key [None]: test
Default region name [None]: us-east-1
Default output format [None]:

aws --endpoint-url=http://localhost:4566 kinesis list-streams
aws --endpoint-url=http://localhost:4566 lambda list-functions
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
```

## X11 forwarding

```
ssh -X homelab
ssh -Y homelab   
xauth list $DISPLAY
echo $DSIPLAY

sudo su - 
xauth add homelab/unix:10  MIT-MAGIC-COOKIE-1  d6c4b66d7e77a9b88011ae46afdec2a8
export DISPLAY=localhost:10.0
```

## Packer

* [Provision Infrastructure with Packer](https://learn.hashicorp.com/tutorials/terraform/packer)
* [Packer QEMU Builder](https://www.packer.io/docs/builders/qemu)
* [Ubuntu packer templates](https://github.com/jakobadam/packer-qemu-templates)
* [VM templates with Packer for usage with Libvirt/KVM virtualization](https://github.com/goffinet/packer-kvm)

```
packer validate packer.json
PACKER_LOG=1 packer build -timestamp-ui packer.json
```

```
git clone https://github.com/goffinet/packer-kvm.git
cd packer-kvm
vi packer.json

{
    "variables":
    {
      "cpu": "2",
      "ram": "2048",
      "name": "focal",
      "disk_size": "40000",
      "version": "",
      "iso_checksum_type": "sha256",
      "iso_urls": "http://releases.ubuntu.com/20.04/ubuntu-20.04.1-live-server-amd64.iso",
      "iso_checksum": "443511f6bf12402c12503733059269a2e10dec602916c0a75263e5d990f6bb93",
      "headless": "true",
      "config_file": "focal",
      "ssh_username": "ubuntu",
      "ssh_password": "ubuntu",
      "destination_server": "download.goffinet.org"
    },
  "builders": [
    {
      "name": "{{user `name`}}{{user `version`}}",
      "type": "qemu",
      "format": "qcow2",
      "accelerator": "kvm",
      "qemu_binary": "/usr/bin/qemu-system-x86_64",
      "net_device": "virtio-net",
      "disk_interface": "virtio",
      "disk_cache": "none",
      "qemuargs": [[ "-m", "{{user `ram`}}M" ],[ "-smp", "{{user `cpu`}}" ]],
      "ssh_wait_timeout": "45m",
      "ssh_timeout": "45m",
      "http_directory": ".",
      "http_port_min": 10082,
      "http_port_max": 10089,
      "ssh_host_port_min": 2222,
      "ssh_host_port_max": 2229,
      "ssh_username": "{{user `ssh_username`}}",
      "ssh_password": "{{user `ssh_password`}}",
      "ssh_handshake_attempts": 500,
      "iso_urls": "{{user `iso_urls`}}",
      "iso_checksum": "{{user `iso_checksum`}}",
      "boot_wait": "3s",
      "boot_command": [
        "<enter><enter><f6><esc><wait>",
        "<bs><bs><bs><bs>",
        "autoinstall net.ifnames=0 biosdevname=0 ip=dhcp ipv6.disable=1 ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/http/{{ user `config_file` }}/ ",
        "--- <enter>"
      ],
      "disk_size": "{{user `disk_size`}}",
      "disk_discard": "ignore",
      "disk_compression": true,
      "headless": "{{user `headless`}}",
      "shutdown_command": "echo '{{user `ssh_password`}}' | sudo -S shutdown -P now",
      "output_directory": "artifacts/qemu/{{user `name`}}{{user `version`}}"
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "execute_command": "{{ .Vars }} sudo -E bash '{{ .Path }}'",
      "inline": [
        "sudo apt-get update",
        "sudo apt-get -y install software-properties-common",
        "sudo apt-add-repository --yes --update ppa:ansible/ansible",
        "sudo apt update",
        "sudo apt -y install ansible"
      ]
    },
    {
      "type": "ansible-local",
      "playbook_file": "ansible/playbook.yml",
      "playbook_dir": "ansible"
    },
    {
      "type": "shell",
      "execute_command": "{{ .Vars }} sudo -E bash '{{ .Path }}'",
      "inline": [
        "sudo apt -y remove ansible",
        "sudo apt-get clean",
        "sudo apt-get -y autoremove --purge"
      ]
    }
  ],
  "post-processors": [
  ]
}
```

```
sudo virt-install \
 --name ubuntu \
 --description "Ubuntu20" \
 --os-type=linux \
 --os-variant=ubuntu18.04 \
 --ram=1024 \
 --vcpus=1 \
 --disk path=artifacts/qemu/focal/packer-focal,device=disk,bus=virtio,size=40,format=qcow2 \
 --graphics none \
 --console pty,target_type=serial \
 --network network:default \
 --graphics spice,listen=127.0.0.1 \
 --import \
 --noautoconsole
```

## ClouInit

* [Ubuntu Cloud Images](http://cloud-images.ubuntu.com/)
* [CloudInit](https://help.ubuntu.com/community/CloudInit)
* [Local KVM image](https://github.com/fabianlee/local-kvm-cloudimage)

```
# download image
wget http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

# original image is 2G, create snapshot and make it 10G
qemu-img create -b bionic-server-cloudimg-amd64.img -f qcow2 snapshot-bionic-server-cloudimg.qcow2 10G

# show snapshot info
qemu-img info snapshot-bionic-server-cloudimg.qcow2

# ssh keys
ssh-keygen -t rsa -b 4096 -f id_rsa -C test1 -N "" -q
```

```
vi cloud_init.cfg

#cloud-config
hostname: test1
fqdn: test1.example.com
manage_etc_hosts: true
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    home: /home/ubuntu
    shell: /bin/bash
    lock_passwd: false
    ssh-authorized-keys:
      - ssh-rsa *** test1
# only cert auth via ssh (console access can still login)
ssh_pwauth: false
disable_root: false
chpasswd:
  list: |
     ubuntu:linux
  expire: False
packages:
  - qemu-guest-agent
# written to /var/log/cloud-init-output.log
final_message: "The system is finally up, after $UPTIME seconds"
```

```
vi network_config_static.cfg

version: 2
ethernets:
  enp1s0:
    dhcp4: false
    # default libvirt network
    addresses: [ 192.168.122.158/24 ]
    gateway4: 192.168.122.1
    nameservers:
      addresses: [ 192.168.122.1,8.8.8.8 ]
```

```
sudo apt-get install -y cloud-image-utils

# insert network and cloud config into seed image
sudo cloud-localds -v --network-config=network_config_static.cfg test1-seed.qcow2 cloud_init.cfg

# show seed disk just generated
qemu-img info test1-seed.qcow2 

sudo apt install  libosinfo-bin      
osinfo-query os| grep ubuntu

sudo virt-install --name test1 \
  --virt-type kvm --memory 2048 --vcpus 2 \
  --boot hd,menu=on \
  --disk path=test1-seed.qcow2,device=cdrom \
  --disk path=snapshot-bionic-server-cloudimg.qcow2,device=disk \
  --graphics vnc \
  --os-type Linux --os-variant ubuntu18.04 \
  --network network:default \
  --console pty,target_type=serial

sudo virsh console test1

ssh ubuntu@192.168.122.158 -i id_rsa

# final cloud-init status
cat /run/cloud-init/result.json

# cloud logs
vi /var/log/cloud-init.log
vi /var/log/cloud-init-output.log

# flag that signals that cloud-init should not run
sudo touch /etc/cloud/cloud-init.disabled

# optional, remove cloud-init completely
sudo apt-get purge cloud-init

# shutdown VM so CDROM seed can be ejected
sudo shutdown -h now

# get name of target path
targetDrive=$(sudo virsh domblklist test1 | grep test1-seed | awk {' print $1 '})

# force ejection of CD
sudo virsh change-media test1 --path $targetDrive --eject --force
```

## KVM

* [Wirtualizacja QEMU/KVM (libvirt) na Debian Linux](https://morfikov.github.io/post/wirtualizacja-qemu-kvm-libvirt-na-debian-linux/)
* [How to install KVM server on Debian Linux 9 Headless Server](https://www.cyberciti.biz/faq/install-kvm-server-debian-linux-9-headless-server/)
* [Correct way to move KVM VM](https://serverfault.com/questions/434064/correct-way-to-move-kvm-vm)
* [Live KVM migration with virsh](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/virtualization_administration_guide/sect-virtualization-kvm_live_migration-live_kvm_migration_with_virsh)
* [How to configure management access to libvirt through SSH](https://wiki.libvirt.org/page/SSHSetup)

### Install packages on Debian and check status of *libvirtd*

```
sudo apt install qemu qemu-kvm qemu-system qemu-utils
sudo apt install libvirt-clients libvirt-daemon-system virtinst virt-top

systemctl status libvirtd
```

### List networks

```
virsh net-list --all
```

### Start network

```
virsh net-start default
virsh net-autostart default
```

### Prepare directories

```
sudo mkdir -pv /kvm/{disk,iso}
```

### List all VMs

```
virsh list  --all

virsh -c qemu:///system list

sudo usermod -G libvirt -a seba        
virsh -c qemu+ssh://seba@homelab/system list
```

### Create new VM

```
virt-install \
 --name debian10 \
 --description "Debian10" \
 --os-type=linux \
 --os-variant=debian10 \
 --ram=1024 \
 --vcpus=1 \
 --disk path=/kvm/disk/debian10.img,device=disk,bus=virtio,size=10,format=qcow2 \
 --graphics none \
 --console pty,target_type=serial \
 --location '/kvm/iso/debian-firmware-10.5.0-amd64-netinst.iso' \
 --extra-args 'console=ttyS0,115200n8 serial' \
 --network network:default \
 --graphics spice,listen=127.0.0.1 \
 --force --debug 

remote-viewer spice://127.0.0.1:5900
remote-viewer vnc://127.0.0.1:5900

virsh dumpxml debian10 | grep vnc
virsh vncdisplay debian10

ssh user@hostname -L 5901:127.0.0.1:5901
```

### Edit config file

```
ls -l /etc/libvirt/qemu/debian10.xml
virsh edit debian10
```

### Operations on VM - start, shutdown, suspend, resume

```
virsh shutdown debian10
virsh start debian10
virsh reboot debian10

virsh suspend debian10
virsh resume debian10
```

### Info about VM

```
virsh dominfo debian10
virsh vncdisplay debian10
virt-top
```

### Connect to console

```
virsh console debian10
```

### Delete VM

```
virsh destroy debian10
virsh undefine debian10
```

### Delete storage pool

```
sudo virsh pool-destroy ubuntu 
sudo virsh pool-delete ubuntu 
sudo virsh pool-undefine ubuntu 
```

## X forwarding

```
ssh -X homelab    
ssh -Y homelab    
```

### Virt builder

```
sudo apt install libguestfs-tools  

virt-builder --list

sudo virt-builder debian-10 \
--size=10G \
--format qcow2 -o /var/lib/libvirt/images/debian10.qcow2 \
--hostname debian10 \
--network \
--timezone Europe/Warsaw

sudo virt-install --import --name debian10 \
--ram 1024 \
--vcpu 1 \
--disk path=/var/lib/libvirt/images/debian10.qcow2,format=qcow2 \
--os-variant debian10 \
--network network:default \
--noautoconsole

virsh console debian10

dpkg-reconfigure openssh-server
useradd -r -m -d /home/seba -s /bin/bash seba
passwd seba
systemctl enable ssh

usermod -aG sudo seba
sudoedit /etc/sudoers
# ...
seba    ALL=(ALL) NOPASSWD:ALL

### [ Disable root user login when using ssh ] ###
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
systemctl restart ssh

cat /etc/network/interfaces
# ...
auto enp1s0
allow-hotplug enp1s0
iface enp1s0 inet dhcp

ip a s

sudo virsh net-dhcp-leases default
```

### Move VM

```
scp /var/lib/libvirt/images/VMNAME seba@hostname:/var/lib/libvirt/images/
virsh dumpxml VMNAME > domxml.xml 
virsh net-dumpxml NETNAME > netxml.xml
scp domxml.xml seba@hostname:/home/seba/
virsh net-define netxml.xml && virsh net-start NETNAME & virsh net-autostart NETNAME
virsh define domxml.xml
```

### Resize disk

```
sudo virsh shutdown debian10     
sudo virsh list --all    
sudo virsh domblklist debian10       
sudo virsh dumpxml debian10 | grep 'disk type' -A 5
sudo qemu-img info /var/lib/libvirt/images/debian10.qcow2         

sudo virsh snapshot-list debian10
sudo virsh snapshot-delete --domain debian10 --snapshotname snapshot1

sudo qemu-img resize /var/lib/libvirt/images/debian10.qcow2 +5G

sudo virsh start debian10
sudo virsh blockresize debian10 /var/lib/libvirt/images/debian10.qcow2 15G  
sudo fdisk -l /var/lib/libvirt/images/debian10.qcow2

lsblk
sudo apt -y install cloud-guest-utils
sudo growpart /dev/vda 1

# if LVM
sudo pvresize /dev/vda1
sudo pvs
sudo vgs
sudo lvextend -l +100%FREE /dev/name-of-volume-group/root
df -hT | grep mapper
## ext4
sudo resize2fs /dev/name-of-volume-group/root
## xfs
sudo xfs_growfs /

# if no LVM
## ext4
sudo resize2fs /dev/vda1
## xfs
sudo xfs_growfs /
```

### Add RAM or CPU to VM

```
sudo virsh dominfo debian10  
sudo virsh edit debian10 
# ...
<memory unit='KiB'>1548576</memory>
# ...
<vcpu placement='static'>1</vcpu>
```

### Create snaphost and restore

```
sudo virsh snapshot-list --domain debian10  
sudo virsh snapshot-create --domain debian10 
sudo virsh snapshot-create-as --domain debian10 \
--name "20201141651" \
--description "Snapshot before upgrading"
sudo virsh dumpxml debian10 | grep 'disk type' -A 5  
qemu-img snapshot -l /var/lib/libvirt/images/debian10.qcow2

sudo virsh shutdown debian10 
sudo virsh snapshot-revert --domain debian10 --snapshotname 20201141651 --running

virsh snapshot-delete --domain debian10 --snapshotname 20201141651
```

## SSL/TLS

Resources about SSL/TLS and certificates:

* [OpenSSL Cookbook](https://www.feistyduck.com/books/openssl-cookbook/)
* [openssl s_client](https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html)
* [certbot](https://certbot.eff.org/)
* [KeyStore Explorer](https://keystore-explorer.org/)
* [Keystore vs. Truststore](https://www.educative.io/edpresso/keystore-vs-truststore)
* [Let's Encrypt](https://letsencrypt.org/)
* [Certbot](https://certbot.eff.org/)

Use following commands to create own certificate:

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

### OpenSSL Cookbook

Command use while learning from book [OpenSSL Cookbook](https://www.feistyduck.com/library/openssl-cookbook/online/ch-openssl.html):

#### Getting started

```bash
openssl version
openssl version -a
openssl help
man ciphers
```

#### Trust Store

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

#### Key and Certificate Management

1. Generate a strong private key,
2. Create a Certificate Signing Request (CSR) and send it to a CA,
3. Install the CA-provided certificate in your web server.

#### Key generation

```bash
openssl genrsa -aes128 -out fd.key 2048
openssl rsa -text -in fd.key
openssl rsa -in fd.key -pubout -out fd-public.key
```

#### Creating Certificate Signing Requests

```bash
# openssl req -new -keyform PEM -key fd.key -outform PEM -out fd.csr -sha256 -batch -subcj "..."
openssl req -new -key fd.key -out fd.csr
openssl req -text -in fd.csr -noout
```

#### Creating Certificate Signing Requests from existing certificate

```
openssl x509 -x509toreq -in fd.crt -out fd.csr -signkey fd.key
```

#### Unattended CSR Generation

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

#### Signing Your Own Certificates

```bash
openssl x509 -req -days 365 -in fd.csr -signkey fd.key -out fd.crt
```

#### Creating Certificates Valid for Multiple Hostnames

```bash
more fd.ext

subjectAltName = DNS:*.feistyduck.com, DNS:feistyduck.com

openssl x509 -req -days 365 \
-in fd.csr -signkey fd.key -out fd.crt \
-extfile fd.ext
```

#### Examining Certificates

```bash
openssl x509 -text -in fd.crt -noout
```

#### PEM and DER Conversion

```bash
openssl x509 -inform PEM -in fd.pem -outform DER -out fd.der
openssl x509 -inform DER -in fd.der -outform PEM -out fd.pem
```

#### PKCS#12 (PFX) Conversion

```bash
# openssl pkcs12 -export \
#    -name "My Certificate" \
#    -out fd.p12 \
#    -inkey fd.key \
#    -in fd.crt \
#    -chain
#    -caname root
#    -CAfile ca.crt

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

#### Obtaining the List of Supported Suites

```bash
openssl ciphers -v 'ALL:COMPLEMENTOFALL'
```

#### Performance

```bash
openssl speed rc4 aes rsa ecdh sha
```

#### Connecting to SSL Services

```
openssl s_client -connect www.google.com:443
openssl s_client -connect www.google.com:443 -servername www.google.com -CAfile self_signed.crt
```

#### SSL server

```bash
openssl s_server -key public.pem -cert cert.crt -accept 8025 -wwww
```

## cURL

Articles:

* [SSL Certificate Verification](https://curl.haxx.se/docs/sslcerts.html)
* [How to curl an endpoint protected by mutual tls (mtls)](https://downey.io/notes/dev/curl-using-mutual-tls/)
* [Using Mutual TLS on the Client Side with Curl](https://smallstep.com/hello-mtls/doc/client/curl)
  
Examples of using:

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

## Security scanning tools

OSS index is free catalogue of open source components. Using public REST API it's possible to [scan your dependencies](https://ossindex.sonatype.org/#integrations-tab-pane). Using Docker we can easily check our packages.

### R

[oysteR](https://github.com/sonatype-nexus-community/oysteR)

```bash
cd containers/security-r
docker build --rm -t centos-r-image .
docker run --name centos-r-container --rm -it centos-r-image
```

### Python

[ossaudit](https://github.com/illikainen/ossaudit)

```bash
cd containers/security-python
docker build --rm -t centos-python-image .
docker run --name centos-python-container --rm -it centos-python-image
```

## Summary

After finishing work we can stop all container using command:

```bash
docker stop $(docker ps -a -q)
```