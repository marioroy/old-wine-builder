# Container to build multi-architecture wine builds, by Yulian Kuncheff
# https://github.com/daegalus/wine-builder
# 
# Building old Portable Executable Wine is possible with Ubuntu 22.04
# Do not change to later Ubuntu release
# Copy recent Linux NTsync header file (included)
#
FROM ubuntu:22.04

ARG USERNAME=wine-builder
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install 32-bit Architecture and sudo
# Make sure everythng is up to date
RUN dpkg --add-architecture i386 \
    && sed -i 's/# deb-src/deb-src/' /etc/apt/sources.list \
    && apt update && apt upgrade -y && apt autoremove -y \
    && apt install -y sudo

# Create a non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

# Install Wine build dependencies
RUN sudo apt build-dep -y wine

# Add packages for FFmpeg, Portable Executable (PE) cross-compiler support,
# SAMBA NetAPI, Scanners, Smart Cards, USB, and more
RUN sudo apt install -y --no-install-recommends \
        libjson-perl libavcodec-dev libavformat-dev libavfilter-dev \
        libswresample-dev libavutil-dev libswscale-dev libpcsclite1 \
        libpcsclite-dev libpcap-dev libsane-dev libusb-1.0-0-dev \
        libxkbregistry-dev libz1 mingw-w64 samba-dev spirv-headers \
    && sudo rm -rf /var/cache/apt/archives /var/cache/apt/lists

# Copy recent Linux "/usr/linux/ntsync.h" header file
# This is done after installing packages so not overwritten
COPY --chown=root:root ntsync.h /usr/include/linux/ntsync.h
RUN sudo chmod 644 /usr/include/linux/ntsync.h

COPY --chown=$USER_UID:$USER_GID build-wine.sh /build-wine.sh
RUN sudo chmod 755 /build-wine.sh

WORKDIR /wine-builder
RUN sudo chown $USER_UID:$USER_GID /wine-builder
RUN sudo chmod 755 /wine-builder

ENTRYPOINT [ "/build-wine.sh" ]
