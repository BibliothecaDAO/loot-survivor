# Use Ubuntu as the base.
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

WORKDIR /app

COPY src ./src
COPY env .
COPY deno.json .

# Copy scripts folder into the container
COPY scripts /scripts

# Make individual scripts executable
RUN chmod +x /scripts/*.sh

# Copy and set permissions for master script
COPY master_script.sh /master_script.sh
RUN chmod +x /master_script.sh

# Run your script
CMD ["/master_script.sh"]
