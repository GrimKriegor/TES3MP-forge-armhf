FROM arm32v7/debian:stretch

LABEL maintainer="Grim Kriegor <grimkriegor@krutt.org>"
LABEL description="A container to simplify the packaging of TES3MP for GNU/Linux"

ARG BUILD_THREADS=4
ENV BUILD_THREADS=${BUILD_THREADS}

ENV PATH=/usr/local/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib

COPY tmp/qemu-arm-static /usr/bin/qemu-arm-static

RUN apt-get update \
    && apt-get -y install build-essential git wget lsb-release \
        unzip libopenal-dev libsdl2-dev libunshield-dev \
        libncurses5-dev libluajit-5.1-dev cmake \
        libboost-all-dev libopenscenegraph-dev

RUN git config --global user.email "nwah@mail.com" \
    && git config --global user.name "N'Wah" \
    && git clone https://github.com/GrimKriegor/TES3MP-deploy.git /deploy

RUN mkdir /build
VOLUME [ "/build" ]

WORKDIR /build
ENTRYPOINT [ "/bin/bash", "/deploy/tes3mp-deploy.sh", "--script-upgrade", "--cmake-local", "--skip-pkgs", "--handle-corescripts", "--server-only" ]
CMD [ "--install", "--make-package" ]
