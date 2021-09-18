FROM centos:7
RUN yum install -y python3 python-pip
COPY install_packages.bash /usr/local/src/install_packages.bash
RUN chmod +x /usr/local/src/install_packages.bash && /usr/local/src/install_packages.bash
COPY audit_packages.bash /usr/local/src/audit_packages.bash
RUN chmod +x /usr/local/src/audit_packages.bash
CMD ["/usr/local/src/audit_packages.bash"]
