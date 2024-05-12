#!/bin/bash

# Define directory and file names
CERT_DIR="/usr/local/lsws/conf/cert"
KEY_FILE="default.key"
CERT_FILE="default.crt"

# Create the directory if it does not exist
mkdir -p "$CERT_DIR"

# Generate the RSA key and certificate
openssl req -x509 -days 365 -newkey rsa:4096 -keyout "$KEY_FILE" -out "$CERT_FILE" -nodes -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com"

# Move the generated key and certificate to the specified directory
mv "$KEY_FILE" "$CERT_DIR"
mv "$CERT_FILE" "$CERT_DIR"

echo "Default self-signed SSL certificate and key have been generated and moved to $CERT_DIR"
