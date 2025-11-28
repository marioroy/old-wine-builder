# Container to build Portable-Executable Wine, by Mario Roy
# Inspired by https://github.com/daegalus/wine-builder
# 
# Uses recent Linux NTsync header file (included)
#
FROM ubuntu:24.04

ARG USERNAME=wine-builder
ARG USER_UID=1001
ARG USER_GID=$USER_UID

# Install 32-bit Architecture
# Append "deb-src" to Types field in ubuntu.sources
# Make sure everythng is up to date and install sudo
RUN dpkg --add-architecture i386 \
    && sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources \
    && apt update && apt upgrade -y && apt autoremove -y \
    && apt install -y sudo

# Add a non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

# Install build dependencies for Wine
RUN sudo apt build-dep -y wine \
    && sudo apt autoclean && sudo apt clean

# Add packages for FFmpeg, Portable Executable (PE) cross-compiler support,
# SAMBA NetAPI, Scanners, and miscellaneous. Prevent systemd installation.
RUN sudo apt-mark hold systemd:amd64 systemd:i386 \
    && sudo apt install -y --no-install-recommends \
        libjson-perl libavcodec-dev libavformat-dev libavfilter-dev \
        libswresample-dev libavutil-dev libswscale-dev libpcap-dev \
        libsane-dev mingw-w64 samba-dev spirv-headers \
    && sudo apt autoclean && sudo apt clean \
    && sudo rm -rf /var/lib/apt/lists/*

# Copy recent Linux "/usr/linux/ntsync.h" header file
# This is done after installing packages so not overwritten
COPY --chown=root:root ntsync.h /usr/include/linux/ntsync.h

# Copy the Wine build script
COPY --chown=$USER_UID:$USER_GID build-wine.sh /build-wine.sh

# Set permissions
RUN sudo chmod 644 /usr/include/linux/ntsync.h \
    && sudo chmod 755 /build-wine.sh

WORKDIR /wine-builder

RUN sudo chown $USER_UID:$USER_GID /wine-builder \
    && sudo chmod 755 /wine-builder

ENTRYPOINT [ "/build-wine.sh" ]

