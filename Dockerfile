FROM arm32v6/debian:jessie as builder

ARG BUILD_THREADS=4

ENV PATH=/usr/local/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib

COPY tmp/qemu-arm-static /usr/bin/qemu-arm-static

RUN cat /etc/apt/sources.list | sed "s/deb /deb-src /g" >> /etc/apt/sources.list \
    && sed -i "s/ main/ main contrib/g" /etc/apt/sources.list \
    && apt-get update && apt-get -y install build-essential git wget

RUN apt-get -y build-dep gcc \
    && apt-get -y install libgmp-dev libmpfr-dev libmpc-dev \
    && cd /tmp \
    && wget ftp://ftp.uvsq.fr/pub/gcc/releases/gcc-6.4.0/gcc-6.4.0.tar.gz \
    && tar xvf gcc-6.4.0.tar.gz \
    && cd gcc-6.4.0 \
    && ./configure --program-suffix=-6 --enable-languages=c,c++ --disable-multilib \
    && make -j ${BUILD_THREADS} \
    && make install \
    && rm -rf /tmp/gcc-6.4.0* \
    && update-alternatives --install /usr/bin/gcc gcc /usr/local/bin/gcc-6 60 \
        --slave /usr/bin/g++ g++ /usr/local/bin/g++-6

RUN apt-get -y build-dep cmake \
    && cd /tmp \
    && git clone https://github.com/Kitware/CMake.git cmake \
    && cd cmake \
    && git checkout tags/v3.5.2 \
    && ./configure --prefix=/usr/local \
    && make -j ${BUILD_THREADS} \
    && make install \
    && rm -rf /tmp/cmake

RUN apt-get -y build-dep libboost-all-dev \
    && apt-get -y install python-dev \
    && cd /tmp \
    && wget https://dl.bintray.com/boostorg/release/1.64.0/source/boost_1_64_0.tar.gz \
    && tar xvf boost_1_64_0.tar.gz \
    && cd boost_1_64_0 \
    && ./bootstrap.sh --with-libraries=program_options,filesystem,system --prefix=/usr/local \
    && ./b2 -j ${BUILD_THREADS} install \
    && rm -rf /tmp/boost_1_64_0*

RUN apt-get -y build-dep libopenscenegraph-dev \
    && cd /tmp \
    && git clone https://github.com/scrawl/osg.git \
    && cd osg \
    && cmake . \
    && cp -a include/* /usr/local/include \
    && rm -rf /tmp/osg

FROM arm32v6/debian:jessie

LABEL maintainer="Grim Kriegor <grimkriegor@krutt.org>"
LABEL description="A container to simplify the packaging of TES3MP for GNU/Linux"

ARG BUILD_THREADS=4
ENV BUILD_THREADS=${BUILD_THREADS}

ENV PATH=/usr/local/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib

COPY --from=builder /usr/local /usr/local

RUN apt-get update \
    && apt-get -y install build-essential git wget lsb-release \
        unzip libopenal-dev libsdl2-dev libunshield-dev \
        libncurses5-dev libluajit-5.1-dev \
    && update-alternatives --install /usr/bin/gcc gcc /usr/local/bin/gcc-6 60 \
        --slave /usr/bin/g++ g++ /usr/local/bin/g++-6

RUN git config --global user.email "nwah@mail.com" \
    && git config --global user.name "N'Wah" \
    && git clone https://github.com/GrimKriegor/TES3MP-deploy.git /deploy

RUN mkdir /build
VOLUME [ "/build" ]

WORKDIR /build
ENTRYPOINT [ "/bin/bash", "/deploy/tes3mp-deploy.sh", "--script-upgrade", "--cmake-local", "--skip-pkgs", "--handle-corescripts", "--server-only" ]
CMD [ "--install", "--make-package" ]
