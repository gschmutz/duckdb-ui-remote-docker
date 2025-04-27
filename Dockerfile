FROM haproxy:bookworm

USER root

ARG TARGETARCH
ARG VERSION
ENV APP_VERSION=$VERSION

# Install curl, OpenSSL, screen, unzip
RUN apt-get update && apt-get install -y curl screen openssl unzip

# Install DuckDB CLI based on architecture
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        DUCKDB_URL="https://github.com/duckdb/duckdb/releases/download/$APP_VERSION/duckdb_cli-linux-aarch64.zip"; \
    elif [ "$TARGETARCH" = "amd64" ]; then \
        DUCKDB_URL="https://github.com/duckdb/duckdb/releases/download/$APP_VERSION/duckdb_cli-linux-amd64.zip"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi && \
    curl -L -o duckdb.zip "$DUCKDB_URL" && \
    unzip duckdb.zip && \
    mv duckdb /usr/local/bin/duckdb && \
    chmod +x /usr/local/bin/duckdb && \
    rm duckdb.zip

# Generate self-signed certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout haproxy.key \
    -out haproxy.crt \
    -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" && \
    cat haproxy.crt haproxy.key > haproxy.pem && \
    chmod 644 haproxy.pem

# Copy custom configuration file from the current directory
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY startup.sh ./startup.sh

# Make the startup script executable
USER root
RUN chmod +x ./startup.sh
USER haproxy

# Expose ports
EXPOSE 8443

# Command to run the application
CMD ["bash", "startup.sh"]
