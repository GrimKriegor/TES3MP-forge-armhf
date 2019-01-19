FROM arm32v7/debian:stretch as builder

ARG BUILD_THREADS=4

COPY tmp/qemu-arm-static /usr/bin/qemu-arm-static

RUN cat /etc/apt/sources.list | sed "s/deb /deb-src /g" >> /etc/apt/sources.list \
    && sed -i "s/ main/ main contrib/g" /etc/apt/sources.list \
    && apt-get update \
    && apt-get -y --reinstall install \
        build-essential \
        git \
        wget

RUN apt-get -y build-dep \
        gcc \
    && apt-get -y install \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev \
    && cd /tmp \
    && wget ftp://ftp.uvsq.fr/pub/gcc/releases/gcc-7.3.0/gcc-7.3.0.tar.gz \
    && tar xvf gcc-7.3.0.tar.gz \
    && cd gcc-7.3.0 \
    && ./configure \
        --program-suffix=-7 \
        --enable-languages=c,c++ \
        --disable-multilib \
        --with-float=hard \
    && make -j ${BUILD_THREADS} \
    && make install \
    && rm -rf /tmp/gcc-7.3.0*

FROM arm32v7/debian:stretch

LABEL maintainer="Grim Kriegor <grimkriegor@krutt.org>"
LABEL description="A container to simplify the packaging of TES3MP for GNU/Linux (armhf version)"

COPY tmp/qemu-arm-static /usr/bin/qemu-arm-static

COPY --from=builder /usr/local /usr/local

RUN apt-get update \
    && apt-get -y install \
        build-essential \
        git \
        wget \
        lsb-release \
        unzip \
        cmake \
        libopenal-dev \
        libsdl2-dev \
        libunshield-dev \
        libncurses5-dev \
        libluajit-5.1-dev \
        libboost-filesystem-dev \
        libboost-thread-dev \
        libboost-program-options-dev \
        libboost-system-dev \
    && update-alternatives \
        --install /usr/bin/gcc gcc /usr/local/bin/gcc-7 60 \
        --slave /usr/bin/g++ g++ /usr/local/bin/g++-7

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
