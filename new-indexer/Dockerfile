# Use a base image. You may choose any base image that suits your needs.
# Here, I'm using Ubuntu as the base.
FROM ubuntu:latest

# Install required packages and set non-interactive for apt-get
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y curl bash && \
    apt-get install -y jq


SHELL ["/bin/bash", "-c"]
ENV PATH="/root/.local/share/apibara/bin:${PATH}"
RUN curl -sL https://install.apibara.com | bash && \
    apibara plugins install sink-console && \
    apibara plugins install sink-mongo

WORKDIR /new-indexer

# To run multiple tasks, you could use a script or use CMD like below.
CMD apibara run --allow-env=env src/adventurers.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1001 && \
    apibara run --allow-env=env src/battles.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1002 && \
    apibara run --allow-env=env src/beasts.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1003 && \
    apibara run --allow-env=env src/discoveries.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1004 && \
    apibara run --allow-env=env src/items.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1005
