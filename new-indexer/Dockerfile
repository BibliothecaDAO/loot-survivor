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

# Copy and set permissions for individual scripts
COPY run_adventurers.sh /run_adventurers.sh
COPY run_battles.sh /run_battles.sh
COPY run_beasts.sh /run_beasts.sh
COPY run_discoveries.sh /run_discoveries.sh
COPY run_items.sh /run_items.sh

# Make individual scripts executable
RUN chmod +x /run_adventurers.sh
RUN chmod +x /run_battles.sh
RUN chmod +x /run_beasts.sh
RUN chmod +x /run_discoveries.sh
RUN chmod +x /run_items.sh

# Copy and set permissions for master script
COPY master_script.sh /master_script.sh
RUN chmod +x /master_script.sh

# Run your script
CMD ["/master_script.sh"]
