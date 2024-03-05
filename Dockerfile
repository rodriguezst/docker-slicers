FROM ghcr.io/linuxserver/baseimage-debian:bookworm

# set version label
ARG BUILD_DATE
ARG VERSION
ARG ORCASLICER_VERSION
ARG CURA_VERSION
ARG CREALITYPRINT_VERSION=v4.3.8
ARG CREALITYPRINT_BUILD=6991
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# title
ENV TITLE=WebSlicer \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    DEBIAN_FRONTEND=noninteractive \
    USER=nomachine \
    PASSWORD=nomachine \
    DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket

RUN apt-get update && apt-get install -y apt-utils vim xterm cups curl \
    mate-desktop-environment-core ssh pulseaudio && \
    service ssh start && \
    mkdir -p /var/run/dbus && \
    curl -fSL "https://www.nomachine.com/free/linux/64/deb" -o nomachine.deb && \
    dpkg -i nomachine.deb && \
    groupadd -r ${USER} -g 433 && \
    useradd -u 431 -r -g ${USER} -d /home/${USER} -s /bin/bash ${USER} && \
    mkdir /home/${USER} && \
    chown -R ${USER}:${USER} /home/${USER} && \
    echo "${USER}:${PASSWORD}" | chpasswd 

ADD nxserver.sh /
ENTRYPOINT ["/nxserver.sh"]

RUN /etc/init.d/dbus start && \
  echo "**** add icon ****" && \
  curl -o \
    /kclient/public/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/orcaslicer-logo.png && \
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
  echo "**** install oracaslicer from appimage ****" && \
  if [ -z ${ORCASLICER_VERSION+x} ]; then \
    ORCASLICER_VERSION=$(curl -sX GET "https://api.github.com/repos/SoftFever/OrcaSlicer/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  cd /tmp && \
  curl -o \
    /tmp/orca.app -L \
    "https://github.com/SoftFever/OrcaSlicer/releases/download/${ORCASLICER_VERSION}/OrcaSlicer_Linux_$(echo ${ORCASLICER_VERSION} | sed 's/\b\(.\)/\u\1/g').AppImage" && \
  chmod +x /tmp/orca.app && \
  ./orca.app --appimage-extract && \
  mv squashfs-root /opt/orcaslicer && \
  echo "**** install cura from appimage ****" && \
  if [ -z ${CURA_VERSION+x} ]; then \
    CURA_VERSION=$(curl -sX GET "https://api.github.com/repos/Ultimaker/Cura/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  cd /tmp && \
  curl -o \
    /tmp/cura.app -L \
    "https://github.com/Ultimaker/Cura/releases/download/${CURA_VERSION}/UltiMaker-Cura-${CURA_VERSION}-linux-X64.AppImage" && \
  chmod +x /tmp/cura.app && \
  ./cura.app --appimage-extract && \
  mv squashfs-root /opt/cura && \
  sed -i 's/QT_QPA_PLATFORMTHEME=xdgdesktopportal/QT_QPA_PLATFORMTHEME=gtk3/' /opt/cura/AppRun.env && \
  echo "**** install crealityprint from appimage ****" && \
  cd /tmp && \
  curl -o \
    /tmp/crealityprint.app -L \
    "https://github.com/CrealityOfficial/CrealityPrint/releases/download/${CREALITYPRINT_VERSION}/Creality_Print-${CREALITYPRINT_VERSION}.${CREALITYPRINT_BUILD}-x86_64-Release.AppImage" && \
  chmod +x /tmp/crealityprint.app && \
  ./crealityprint.app --appimage-extract && \
  mv squashfs-root /opt/crealityprint && \
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
