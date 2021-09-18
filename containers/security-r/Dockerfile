FROM centos:7
RUN yum install -y epel-release
RUN yum install -y R
RUN yum install -y libcurl-devel openssl-devel
COPY audit_packages.R /usr/local/src/audit_packages.R
COPY install_packages.R /usr/local/src/install_packages.R
RUN chmod +x /usr/local/src/install_packages.R && R -f /usr/local/src/install_packages.R
CMD ["R", "-f", "/usr/local/src/audit_packages.R"]