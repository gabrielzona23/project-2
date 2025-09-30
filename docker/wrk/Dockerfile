FROM alpine:3.19

# Install required tools
RUN apk add --no-cache \
    curl \
    wget \
    apache2-utils \
    python3 \
    py3-pip \
    jq \
    bash

# Install wrk (HTTP benchmarking tool)
RUN apk add --no-cache --virtual .build-deps \
    build-base \
    git \
    perl \
    linux-headers \
    && git clone https://github.com/wg/wrk.git /tmp/wrk \
    && cd /tmp/wrk \
    && make \
    && cp wrk /usr/local/bin/ \
    && rm -rf /tmp/wrk \
    && apk del .build-deps

# Install k6
RUN apk add --no-cache --virtual .build-deps \
    gnupg \
    && wget -q -O- https://github.com/grafana/k6/releases/download/v0.47.0/k6-v0.47.0-linux-amd64.tar.gz | tar -xz \
    && mv k6-v0.47.0-linux-amd64/k6 /usr/local/bin/ \
    && rm -rf k6-v0.47.0-linux-amd64 \
    && apk del .build-deps

# Install Python packages for analysis
RUN pip3 install --break-system-packages \
    matplotlib \
    pandas \
    numpy

# Copy benchmark scripts
COPY scripts/ /benchmark/

# Make scripts executable
RUN chmod +x /benchmark/*.sh

WORKDIR /benchmark

# Default command
CMD ["bash"]