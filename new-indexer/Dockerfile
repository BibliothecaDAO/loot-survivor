# Use a base image. You may choose any base image that suits your needs.
# Here, I'm using Ubuntu as the base.
FROM ubuntu:latest

# Install required packages and set non-interactive for apt-get
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y curl bash

# Install Apibara
RUN curl -sL https://install.apibara.com | bash

# Install Apibara plugins
RUN apibara plugins install sink-console
RUN apibara plugins install sink-mongo

# Copy source code into container. Assume that your source code is in the "src" directory.
COPY src/ /app/src/

# Change working directory
WORKDIR /app

# Run apibara tasks. Note that "indexer" and "dna_XXX" are placeholders, you'll need to replace them.
# To run multiple tasks, you could use a script or use CMD like below.
CMD apibara run --allow-env=env src/adventurers.ts -A dna_jX3t04zs9zywBnHWVmUq && \
    apibara run --allow-env=env src/battles.ts -A dna_jX3t04zs9zywBnHWVmUq && \
    apibara run --allow-env=env src/beasts.ts -A dna_jX3t04zs9zywBnHWVmUq && \
    apibara run --allow-env=env src/discoveries.ts -A dna_jX3t04zs9zywBnHWVmUq && \
    apibara run --allow-env=env src/items.ts -A dna_jX3t04zs9zywBnHWVmUq
