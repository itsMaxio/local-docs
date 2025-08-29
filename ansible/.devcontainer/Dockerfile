FROM mcr.microsoft.com/devcontainers/python

RUN apt-get update && apt-get install -y \
    openssh-client \
    git \
    sshpass \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://get.docker.com | sh

RUN pip install --upgrade \
    pip \
    pytz \
    molecule-plugins[docker] \
    docker \
    ansible

WORKDIR /ansible