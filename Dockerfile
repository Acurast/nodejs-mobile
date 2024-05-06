FROM python:3.11-slim-bullseye

RUN apt-get update && \
    apt-get install -yq build-essential gcc-multilib g++-multilib rsync curl unzip

RUN mkdir /nodejs
WORKDIR /nodejs

RUN curl https://dl.google.com/android/repository/android-ndk-r26d-linux.zip -o ndk.zip
RUN unzip ndk.zip

COPY . /nodejs/