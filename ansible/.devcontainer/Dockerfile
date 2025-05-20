FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    openssh-client \
    git \
    sshpass \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip && \
    pip install ansible

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir -p /home/$USERNAME/.ssh \
    && chown -R $USER_UID:$USER_GID /home/$USERNAME/.ssh

RUN mkdir -p /ansible \
    && chown -R $USER_UID:$USER_GID /ansible \
    && chmod 755 /ansible

USER $USERNAME
WORKDIR /ansible