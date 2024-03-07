FROM ghcr.io/linuxserver/baseimage-debian:bookworm

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# env
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    DEBIAN_FRONTEND=noninteractive \
    DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket

RUN echo "**** installing nomachine dependencies ****" && \
  apt-get update && apt-get install -y apt-utils vim xterm cups curl \
  openbox ssh pulseaudio sudo dbus-x11 && \
  mkdir -p /var/run/dbus && \
  echo "**** install packages ****" && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install --no-install-recommends -y \
    firefox-esr \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-qt5 \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    libgstreamer1.0 \
    libgstreamer-plugins-bad1.0 \
    libgstreamer-plugins-base1.0 \
    libwebkit2gtk-4.0-37 \
    libwx-perl && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /config/.launchpadlib \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files
COPY /root /

# ports and volumes (ssh, nomachine & web)
EXPOSE 22 4000 4443
VOLUME /config
