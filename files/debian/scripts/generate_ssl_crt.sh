#!/bin/bash

DOMAIN=$1
# Copy root certificate to this share to import the certificate in the browser
SHARE_PATH=$2

# Define the certificate details
subj="/C=US/ST=State/L=City/O=Organization/OU=Department/CN=*.${DOMAIN}"

# Root certificate and key names
ROOT_KEY="/etc/ssl/private/rootCA.key"
ROOT_CERT="/etc/ssl/certs/rootCA.crt"

# Check if root certificate exists, if not, create one
if [[ ! -f "$ROOT_KEY" ]] || [[ ! -f "$ROOT_CERT" ]]; then
    # Create root key
    openssl genpkey -algorithm RSA -out $ROOT_KEY
    chmod 600 $ROOT_KEY
    
    # Create root certificate
    openssl req -new -x509 -key $ROOT_KEY -out $ROOT_CERT -subj "$subj" -days 3650
    
    # Optionally copy the root certificate to a share
    if [[ -n "$SHARE_PATH" ]]; then
        if [[ ! -d "$SHARE_PATH" ]]; then
            mkdir -p $SHARE_PATH
        fi
        echo "Copy $ROOT_CERT to $SHARE_PATH"
        cp -p $ROOT_CERT $SHARE_PATH
    fi
fi

# Create private key for server
SERVER_KEY="/etc/ssl/private/${DOMAIN}.key"
openssl genpkey -algorithm RSA -out $SERVER_KEY
chmod 600 $SERVER_KEY

# Create the CSR (Certificate Signing Request)
CSR="/etc/ssl/private/${DOMAIN}.csr"
openssl req -new -key $SERVER_KEY -out $CSR -subj "$subj"

# Now, we need to make sure the v3.ext file is set up to include DNS entries in the SAN (Subject Alternative Name)
EXT_FILE="/etc/ssl/${DOMAIN}.ext"
cat >$EXT_FILE <<-EOL
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}
EOL

# Sign the certificate
SIGNED_CERT="/etc/ssl/certs/${DOMAIN}.crt"
openssl x509 -req -in $CSR -CA $ROOT_CERT -CAkey $ROOT_KEY -CAcreateserial -out $SIGNED_CERT -days 3650 -sha256 -extfile $EXT_FILE