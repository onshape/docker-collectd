# Dockerfile for base collectd install

FROM ubuntu:15.04
MAINTAINER SignalFx Support <support+collectd@signalfx.com>

# Install common softwares
ENV DEBIAN_FRONTEND noninteractive

# Install all apt-get utils and required repos 
RUN apt-get install -y apt-transport-https software-properties-common curl vim
RUN add-apt-repository ppa:signalfx/collectd-release && add-apt-repository ppa:signalfx/collectd-plugin-release
RUN apt-get update && apt-get -y upgrade

# Install SignalFx Plugin and collectd
RUN apt-get install -y signalfx-collectd-plugin collectd jq

# clean up existing configs
RUN rm -rf /etc/collectd

# Setup our collectd
ADD configs /etc/

# Setup startup
ADD run.sh /.docker/

WORKDIR /.docker/
CMD /.docker/run.sh
