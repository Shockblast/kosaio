# syntax=docker/dockerfile:1.4

FROM ubuntu:24.10
SHELL ["/bin/bash", "-c"]

LABEL maintainer="Shockblast <danielmaccomb@gmail.com>"
LABEL description="Dreamcast development environment using Kosaio."

# Avoid interactive messages
ENV DEBIAN_FRONTEND=noninteractive

# Install minimal tools
RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y git nano vim ca-certificates crudini && \
	apt-get clean && \
	git config --global pull.rebase true && \
	git config --global core.fileMode false

# Global environment variables
ENV DREAMCAST_SDK="/opt/toolchains/dc"
ENV DREAMCAST_SDK_EXTRAS="${DREAMCAST_SDK}/extras"
ENV DREAMCAST_BIN_PATH="${DREAMCAST_SDK}/bin"
ENV PROJECTS_DIR="/opt/projects"
ENV KOSAIO_DIR="/opt/kosaio"
ENV KOSAIO_CONFIG="/root/.kosaio.conf"
ENV PATH="${DREAMCAST_BIN_PATH}:${PATH}"
ENV PATH="${KOSAIO_DIR}/scripts:${PATH}"
ENV TARGET_DIRS="${DREAMCAST_SDK} ${DREAMCAST_SDK_EXTRAS} ${DREAMCAST_BIN_PATH} ${PROJECTS_DIR} ${KOSAIO_DIR}"

# Get KOSAIO from github
RUN git clone https://github.com/Shockblast/kosaio.git "${KOSAIO_DIR}"

# Make folders and
RUN mkdir -p ${TARGET_DIRS}

# Set Permissions
RUN find ${TARGET_DIRS} -type d -exec chmod 755 {} + && \
	find ${TARGET_DIRS} -type f -exec chmod 755 {} + && \
	chown -R root:root ${TARGET_DIRS}

# Set working directory to /opt/projects
WORKDIR ${PROJECTS_DIR}

# Use bash by default on entry
CMD ["/bin/bash"]
