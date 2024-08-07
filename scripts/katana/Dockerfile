# Use Debian Bookworm as a base image
FROM debian:bookworm-slim

WORKDIR /root

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install minimal utilities
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        git \
        ca-certificates \
        unzip \
        jq \
        bc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Clone loot survivor
RUN git clone --branch main https://github.com/Provable-Games/loot-survivor.git && cd loot-survivor

# Install scarb v2.6.5
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | bash -s -- -v 2.6.5

# Change working directory to loot-survivor repo
WORKDIR /root/loot-survivor

# Build loot survivor
RUN /root/.local/bin/scarb build

# Install starkli v0.3.3
RUN curl https://get.starkli.sh | bash
RUN /root/.starkli/bin/starkliup -v 0.2.9

# Install DOJO
RUN curl -L https://install.dojoengine.org | bash
RUN /root/.dojo/bin/dojoup -v v0.7.4

# Copy the start script
COPY katana_start.sh /root/katana_start.sh
RUN chmod +x /root/katana_start.sh

# Set static environment variables
ENV STARKNET_RPC="http://127.0.0.1:5050"
ENV STARKLI_NO_PLAIN_KEY_WARNING="true"
ENV STARKNET_ACCOUNT="/katana/starkli_account"

# Expose 5050 for katana
EXPOSE 5050

# Start katana when container starts
CMD ["/root/katana_start.sh"]
