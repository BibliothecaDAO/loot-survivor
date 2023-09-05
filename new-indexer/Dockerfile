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

# # To run multiple tasks, you could use a script or use CMD like below.
# CMD apibara run --allow-env=env src/adventurers.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1001 && \
#     apibara run --allow-env=env src/battles.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1002 && \
#     apibara run --allow-env=env src/beasts.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1003 && \
#     apibara run --allow-env=env src/discoveries.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1004 && \
#     apibara run --allow-env=env src/items.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1005

# Copy and set permissions
COPY apibara-script.sh /apibara-script.sh
RUN chmod +x /apibara-script.sh

# Run your script
CMD ["/apibara-script.sh"]

