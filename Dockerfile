FROM arm32v7/debian:buster

LABEL maintainer="Grim Kriegor <grimkriegor@krutt.org>"
LABEL description="A container to simplify the packaging of TES3MP for GNU/Linux (armhf version)"

ENV FORGE_VERSION 1.1.0

COPY tmp/qemu-arm-static /usr/bin/qemu-arm-static

RUN apt-get update \
    && apt-get -y install \
        build-essential \
        git \
        wget \
        lsb-release \
        liblz4-dev \
        unzip \
        cmake \
        libopenal-dev \
        libsdl2-dev \
        libunshield-dev \
        libncurses5-dev \
        libluajit-5.1-dev \
        libboost-all-dev

RUN git clone --depth 1 https://github.com/OpenMW/osg.git /tmp/osg \
    && cd /tmp/osg \
    && cmake . \
    && cp -a /tmp/osg/include/* /usr/include/ \
    && rm -rf /tmp/osg

RUN git config --global user.email "nwah@mail.com" \
    && git config --global user.name "N'Wah" \
    && git clone https://github.com/GrimKriegor/TES3MP-deploy.git /deploy \
    && mkdir /build

VOLUME [ "/build" ]
WORKDIR /build

ENTRYPOINT [ "/bin/bash", "/deploy/tes3mp-deploy.sh", "--script-upgrade", "--skip-pkgs", "--handle-corescripts", "--server-only" ]
CMD [ "--install", "--make-package" ]
