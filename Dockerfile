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
        ca-certificates \
        curl \
        less \
        procps \
        ; \
    # Create a 'app' user which the application will run as
    groupadd app && \
    useradd -M -d /app -s /bin/false -g app app && \
    python3 -m venv /app && \
    printf -- '%s\n' >| /app/bin/entrypoint.sh \
        '#!/usr/bin/env bash' '' \
        'set -e' '' '. /app/bin/activate' '' \
        'if [ 0 -eq $(id -u) ]; then' \
        '  # Change runtime user UID and GID' \
        '  PGID="${PGID:-1100}"' \
        '  groupmod -o -g "$PGID" app' \
        '  PUID="${PUID:-1100}"' \
        '  usermod -o -u "$PUID" app' '' \
        '  chown app "${HOME}"' \
        '  chgrp -R app "${HOME}"' \
        '  chmod -R g+w "${HOME}"' \
        '  su --preserve-environment --session-command "pip install --upgrade pip" -s /bin/sh -g app app' \
        'else' \
        '  pip install --upgrade pip || :' \
        'fi' '' \
        '' 'exec "$@"' \
        && \
    chmod -c 00755 /app/bin/entrypoint.sh && \
    chown -R root:app /app && \
    install -d -o root -g root -m 01777 /cache

VOLUME ["/cache"]
WORKDIR /app

ENV HOME="/app" \
    PYTHONPYCACHEPREFIX="/cache/pycache" \
    XDG_CACHE_HOME="/cache"

ENTRYPOINT ["/app/bin/entrypoint.sh"]
CMD ["pip", "list"]
