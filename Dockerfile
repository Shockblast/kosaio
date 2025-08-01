# syntax=docker/dockerfile:1.4

FROM ubuntu:24.10
SHELL ["/bin/bash", "-c"]

LABEL maintainer="Shockblast <danielmaccomb@gmail.com>"
LABEL description="Dreamcast development environment with KallistiOS, GLdc, ALdc and more."

# Avoid interactive messages
ENV DEBIAN_FRONTEND=noninteractive

# Install minimal tools
RUN apt-get update && apt-get upgrade -y && \
	apt-get install -y --no-install-recommends git nano vim ca-certificates && \
	apt-get clean && \
	git config --global pull.rebase true

# Global environment variables
ENV DREAMCAST_SDK="/opt/toolchains/dc"
ENV DREAMCAST_SDK_EXTRAS="${DREAMCAST_SDK}/extras"
ENV DREAMCAST_BIN_PATH="${DREAMCAST_SDK}/bin"
ENV PROJECTS_DIR="/opt/projects"
ENV KOSAIO_DIR="/opt/kosaio"
ENV KOSAIO_SCRIPTS="${KOSAIO_DIR}/scripts"
ENV KOSAIO_BASIC_PROJECT="${KOSAIO_DIR}/basic-project"
ENV KOSAIO_VSCODE_SETTINGS="${KOSAIO_BASIC_PROJECT}/.vscode"
ENV PATH="${DREAMCAST_BIN_PATH}:${PATH}"
ENV PATH="${KOSAIO_SCRIPTS}:${PATH}"
ENV TARGET_DIRS="${DREAMCAST_SDK} ${DREAMCAST_SDK_EXTRAS} ${DREAMCAST_BIN_PATH} ${PROJECTS_DIR} ${KOSAIO_DIR} ${KOSAIO_BASIC_PROJECT}"

# Get KOSAIO from github
RUN git clone https://github.com/Shockblast/kosaio.git "${KOSAIO_DIR}"

# Make folders and 
RUN mkdir -p ${TARGET_DIRS}

# Set Permissions
RUN find ${TARGET_DIRS} -type d -exec chmod 755 {} + && \
	find ${TARGET_DIRS} -type f -exec chmod 644 {} + && \
	chown -R root:root ${TARGET_DIRS}

# Install system dependencies and clone KOS and KOS-PORTS using kosaio
RUN kosaio kos dependencies && kosaio kos clone

# Copy personal configuration before build KOS
COPY dc-chain-settings/Makefile.cfg ${DREAMCAST_SDK}/kos/utils/dc-chain

# Build dc-chain
RUN kosaio kos build-dc-chain

# Required KOS files for build
RUN cp "${DREAMCAST_SDK}/kos/doc/environ.sh.sample" "${DREAMCAST_SDK}/kos/environ.sh"

## Configure interactive environment for bash
RUN echo "source ${DREAMCAST_SDK}/kos/environ.sh" >>/root/.bashrc

# Build KOS
RUN source ${DREAMCAST_SDK}/kos/environ.sh && \
	kosaio kos build-kos && kosaio kos build-kos-ports

# Set working directory to /opt/projects
WORKDIR ${PROJECTS_DIR}

RUN unset TARGET_DIRS

# Use bash by default on entry
CMD ["/bin/bash"]
