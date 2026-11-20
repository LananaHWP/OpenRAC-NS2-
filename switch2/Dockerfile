# The builder for OpenRAC on the Nintendo Switch 2: devkitPro's public devkitA64 image, OunceDevKit (libounce, a libnx-compatible library, and
# OunceVK: Vulkan, EGL and OpenGL) installed from source, and Clang (hostgen reads the decompilation with it).
FROM docker.io/devkitpro/devkita64:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends git curl xz-utils ca-certificates clang llvm lld ccache python3 \
    && rm -rf /var/lib/apt/lists/* \
    && dkp-pacman -Syu --noconfirm switch-dev switch-tools libnx \
    && dkp-pacman -Scc --noconfirm

# libounce / OunceVK / libkaihen over devkitPro.
RUN git clone --depth=1 https://github.com/ouncebrew/ounce-devkit /opt/ounce-devkit \
    && cd /opt/ounce-devkit \
    && sh install.sh

ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITA64=/opt/devkitpro/devkitA64
ENV PATH="${DEVKITA64}/bin:${DEVKITPRO}/tools/bin:${PATH}"

WORKDIR /build
