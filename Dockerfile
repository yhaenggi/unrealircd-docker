ARG ARCH
FROM ${ARCH}/ubuntu:focal
MAINTAINER yhaenggi <yhaenggi-git-public@darkgamex.ch>

ARG ARCH
ENV ARCH=${ARCH}
ARG VERSION
ENV VERSION=${VERSION}

COPY ./qemu-x86_64-static /usr/bin/qemu-x86_64-static
COPY ./qemu-arm-static /usr/bin/qemu-arm-static
COPY ./qemu-aarch64-static /usr/bin/qemu-aarch64-static

WORKDIR /tmp/

# set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends wget ca-certificates gpg gpg-agent dirmngr build-essential cmake -y && apt-get clean && rm -Rf /var/cache/apt/ && rm -Rf /var/lib/apt/lists

RUN gpg --keyserver pgp.mit.edu --recv-keys 0xA7A21B0A108FF4A9
RUN wget https://www.unrealircd.org/downloads/unrealircd-${VERSION}.tar.gz
RUN wget https://www.unrealircd.org/downloads/unrealircd-${VERSION}.tar.gz.asc
RUN gpg --verify unrealircd-${VERSION}.tar.gz.asc unrealircd-${VERSION}.tar.gz

RUN tar xvf unrealircd-${VERSION}.tar.gz
WORKDIR /tmp/unrealircd-${VERSION}/

RUN apt-get update && apt-get install pkg-config libssl-dev libargon2-0-dev libsodium-dev libc-ares-dev libpcre2-dev -y && apt-get clean && rm -Rf /var/cache/apt/ && rm -Rf /var/lib/apt/lists

RUN groupadd -r ircd && useradd -r -m -g ircd ircd
RUN chown -R ircd:ircd /tmp/unrealircd-${VERSION}/
USER ircd

ENV TERM=vt100
RUN ls -al 
RUN ./Config
RUN nice -n 20 make -j$(nproc)
RUN nice -n 20 make -j$(nproc) install

FROM ${ARCH}/ubuntu:focal
MAINTAINER yhaenggi <yhaenggi-git-public@darkgamex.ch>

ARG ARCH
ENV ARCH=${ARCH}
ARG VERSION
ENV VERSION=${VERSION}

COPY ./qemu-x86_64-static /usr/bin/qemu-x86_64-static
COPY ./qemu-arm-static /usr/bin/qemu-arm-static
COPY ./qemu-aarch64-static /usr/bin/qemu-aarch64-static

WORKDIR /tmp/

# set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends libargon2-0 libc-ares2 openssl libsodium23 -y && apt-get clean && rm -Rf /var/cache/apt/ && rm -Rf /var/lib/apt/lists

RUN groupadd -r ircd && useradd -r -m -g ircd ircd
COPY --from=0 /home/ircd/unrealircd/ /home/ircd/unrealircd/
RUN chown -R ircd:ircd /home/ircd/
WORKDIR /home/ircd/unrealircd

RUN rm /usr/bin/qemu-x86_64-static /usr/bin/qemu-arm-static /usr/bin/qemu-aarch64-static

USER ircd

EXPOSE 6667/tcp
EXPOSE 6697/tcp

ENTRYPOINT [""]
CMD ["/home/ircd/unrealircd/bin/unrealircd"]
