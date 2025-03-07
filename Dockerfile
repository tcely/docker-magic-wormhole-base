# syntax=docker/dockerfile:1
# check=error=true

ARG DEBIAN_VERSION='bookworm-slim'
ARG PYTHON_VERSION="3.12-${DEBIAN_VERSION##*-}-${DEBIAN_VERSION%%-*}"

FROM python:${PYTHON_VERSION} AS magic-wormhole-base

ENV DEBIAN_FRONTEND="noninteractive" \
    HOME="/root" \
    LANGUAGE="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    TERM="xterm" \
    # Do not include compiled byte-code
    PIP_NO_COMPILE=1 \
    PIP_ROOT_USER_ACTION='ignore'

RUN set -eux; \
    # Update from the network and keep cache
    rm -v -f /etc/apt/apt.conf.d/docker-clean && \
	apt-get update ; \
    # Install locales
    apt-get install -y --no-install-recommends locales && \
    printf -- "en_US.UTF-8 UTF-8\n" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 ; \
	apt-get install -y --no-install-recommends \
        curl \
        less \
        procps

