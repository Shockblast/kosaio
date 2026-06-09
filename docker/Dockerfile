FROM ubuntu:24.04

LABEL maintainer="Shockblast <danielmaccomb@gmail.com>"
LABEL description="Dreamcast development environment using Kosaio."

# Global Environment Variables
ENV DEBIAN_FRONTEND=noninteractive
ENV KOSAIO_DIR="/opt/kosaio"
ENV PROJECTS_DIR="/opt/projects"
# Minimal PATH to ensure kosaio script is found
ENV PATH="${KOSAIO_DIR}/scripts:${PATH}"

# Copy Provisioning Scripts and Configs
# We copy the entire scripts and configs folders to ensure relative paths work
COPY ./scripts/ /opt/kosaio/scripts/
COPY ./configs/ /opt/kosaio/configs/

# Execute Provisioning
RUN chmod +x /opt/kosaio/scripts/provision.sh && \
    /opt/kosaio/scripts/provision.sh

# Global Shell Setup
RUN echo "source /opt/kosaio/scripts/shell-init.sh" >> /root/.bashrc

# Set Working Directory
WORKDIR ${PROJECTS_DIR}

# Entry
CMD ["/bin/bash"]
