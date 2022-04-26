FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
  apt-get install -y gcc python-dev libkrb5-dev && \
  apt-get install python3-pip ansible sudo  -y && \
  pip3 install --upgrade pip && \
  pip3 install --upgrade virtualenv && \
  pip3 install pywinrm[kerberos] && \
  apt install krb5-user wget vim git curl sshpass -y && \ 
  pip3 install pywinrm jinja2 jmespath

# init
RUN useradd pulsar
RUN adduser pulsar sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN mkdir -p  /home/pulsar/.ssh
RUN chown -R pulsar:pulsar /home/pulsar
USER pulsar
