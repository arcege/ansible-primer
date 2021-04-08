# Dockerfile for primer images
# this isn't anything special
# * expose some ports that may be used later
# * install commands needed
# * setup `docker-systemctl-replacement`
# * create a 'docker' user for Ansible to use
# * add the generated ssh-key to authorized_keys

# the result is a docker container that runs a
# mocked out systemd system

ARG BASEIMAGE
FROM ${BASEIMAGE}

# these ports may be used during lessons
# http
EXPOSE 80
# redis
EXPOSE 6379
# redis/alt
EXPOSE 7379

RUN if command -v apt-get; then \
        apt-get update && \
        apt-get upgrade -y && \
        export DEBIAN_FRONTEND=noninteractive && \
        apt-get install --no-install-recommends -y sudo systemd init python3 \
            python3-pip unzip curl openssh-server openssh-sftp-server && \
        apt-get purge -y && apt-get clean && \
        ln -sf python3 /usr/bin/python2 && \
        mkdir -p /run/systemd/system; \
    elif command -v yum; then \
        yum repolist -y && \
        yum update -y && \
        yum install -y systemd sudo python3 shadow-utils unzip openssh-server && \
        rm -rf /var/cache/yum && \
        if command -v amazon-linux-extras; then \
            amazon-linux-extras install -y epel; \
        fi && \
        /usr/bin/ssh-keygen -A && \
        rm -f /run/nologin && \
        if test ! -e /usr/bin/python; then \
            ln -s python3 /usr/bin/python; \
            ln -s python3 /usr/bin/python2; \
        fi && \
        yum clean all && rm -rf /var/cache/yum; \
    fi
RUN mkdir -p /run/systemd/system
COPY docker-systemctl-replacement.py /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl
ENTRYPOINT ["/usr/bin/systemctl", "default"]

RUN useradd -m -s /bin/bash docker && echo 'docker ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

COPY ssh-key.pub /home/docker/.ssh/authorized_keys
RUN chown -R docker:docker /home/docker/.ssh && chmod -R go-rwx /home/docker/.ssh

USER docker
WORKDIR /home/docker
