FROM centos:7
RUN yum install -y python3 python-pip
COPY script.bash /usr/local/src/script.bash
RUN chmod +x /usr/local/src/script.bash
CMD ["/usr/local/src/script.bash"]