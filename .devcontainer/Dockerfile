# Use Debian Bookworm as a base image
FROM debian:bookworm-slim

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install minimal utilities
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        git \
        ca-certificates \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh
RUN curl https://get.starkli.sh | bash
RUN /root/.starkli/bin/starkliup
# Specify the command to run on container start
CMD ["bash"]