FROM python:latest

RUN apt-get update \
    && apt-get install -y \
    ansible \
    sshpass \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ansible