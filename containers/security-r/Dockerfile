FROM centos:7
RUN yum install -y epel-release && yum install -y R
COPY script.R /usr/local/src/script.R
CMD ["R", "-f", "/usr/local/src/script.R"]