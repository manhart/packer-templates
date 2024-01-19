#!/bin/bash

VHOSTS_FILE="/vagrant/vhosts.json"

if [[ ! -f "$VHOSTS_FILE" ]] || [[ ! -r "$VHOSTS_FILE" ]]; then
  echo "ERROR: File $VHOSTS_FILE does not exist or is not readable."
  exit 1
fi

SSL_DEST_DIR="/vagrant/ssl"
SITES_AVAILABLE_DIR="/etc/apache2/sites-available"
APACHE_LOG_DIR="/var/log/apache2"

if [ ! -d "$SITES_AVAILABLE_DIR" ]; then
    echo "Das Verzeichnis $SITES_AVAILABLE_DIR existiert nicht, setup_vhosts aborted."
    exit 1
fi

DELETE_ALL_VHOSTS=false

# Überprüfen Sie, ob ein entsprechender Parameter übergeben wurde
if [ "$1" == "--delete-all-vhosts" ]; then
  DELETE_ALL_VHOSTS=true
fi

if [ "$DELETE_ALL_VHOSTS" = true ] ; then
	# Remove alle existing vhosts
	cd "$SITES_AVAILABLE_DIR"
	for config_file in *; do
		# Überprüfen Sie, ob der Dateiname nicht mit "pinned-" beginnt
		if [[ ! $config_file =~ ^pinned- ]]; then
			# Deaktivieren Sie die Site, falls diese aktiv ist.
			sudo a2dissite "$config_file"
        
			# Löschen Sie die Konfigurationsdatei
			sudo rm -f "$config_file"
		fi
	done
fi

# Loop through each vhost
vhost_count=$(jq 'length' "$VHOSTS_FILE")
for (( i=0; i<$vhost_count; i++ )); do
  SERVER_NAME=$(jq -r ".[$i].server_name" "$VHOSTS_FILE")
  SERVER_ALIAS=$(jq -r ".[$i].server_alias | select (.!=null)" "$VHOSTS_FILE")
  DOCUMENT_ROOT=$(jq -r ".[$i].document_root" "$VHOSTS_FILE")
  ENABLE_HTTP=$(jq -r ".[$i].enable_http" "$VHOSTS_FILE")
  ENABLE_HTTPS=$(jq -r ".[$i].enable_https" "$VHOSTS_FILE")
  ADD_OPTIONAL_INCLUDE=$(jq -r ".[$i].include_optional" "$VHOSTS_FILE") $(echo "$VHOST" | jq -r '.include_optional')
  if [[ $(jq ".[$i].env_vars" "$VHOSTS_FILE") != "null" ]]; then
    ENV_VARS=$(jq -r ".[$i].env_vars" "$VHOSTS_FILE")
    ENV_VARS_COUNT=$(echo "$ENV_VARS" | jq 'keys | length')
  else
    ENV_VARS_COUNT=0
  fi
  if [[ $(jq ".[$i].aliases" "$VHOSTS_FILE") != "null" ]]; then
    ALIASES=$(jq -r ".[$i].aliases" "$VHOSTS_FILE")
    ALIASES_COUNT=$(echo "$ALIASES" | jq 'keys | length')
  else
    ALIASES_COUNT=0
  fi
  
  VHOST_FILE="$SITES_AVAILABLE_DIR/${SERVER_NAME}.conf"

  if [[ ! -f "$VHOST_FILE" ]]; then
    # HTTP VHost
    if [[ "$ENABLE_HTTP" == "true" ]]; then
      cat <<EOF > "$VHOST_FILE"
<VirtualHost *:80>
    ServerName $SERVER_NAME
$(if [ ! -z "$SERVER_ALIAS" ]; then
        ALIAS_STR=$(echo "$SERVER_ALIAS" | jq -r 'join(" ")')
        echo "    ServerAlias $ALIAS_STR"
    fi)
    DocumentRoot $DOCUMENT_ROOT
$(if [[ $ENV_VARS_COUNT -gt 0 ]]; then
for (( j=0; j<$ENV_VARS_COUNT; j++ )); do
    KEY=$(echo "$ENV_VARS" | jq -r "keys[$j]")
    VALUE=$(echo "$ENV_VARS" | jq -r ".[\"$KEY\"]")
    echo "    SetEnv $KEY \"$VALUE\""
  done
fi)
    AllowEncodedSlashes On
    # we deactivate sendfile for faster static content delivery, because it (pagecache) can make problems with nfs, smb, ... shares
    EnableSendfile Off
    # disabling HSTS will allow your site to be publicly viewed over HTTP and/or insecure HTTPS connection
    Header unset Strict-Transport-Security
    Header always set Strict-Transport-Security "max-age=0;includeSubDomains"
    # activate HTTP/2 protocol
    Protocols h2 h2c http/1.1
    <Directory $DOCUMENT_ROOT>
        Options Indexes FollowSymLinks
        DirectoryIndex index.php index.html
        AllowOverride All
        Require all granted
    </Directory>
    <filesMatch ".(js|css|)$">
        Header set Cache-Control "no-cache" 
    </filesMatch>
	
$(if [[ $ALIASES_COUNT -gt 0 ]]; then
for (( j=0; j<$ALIASES_COUNT; j++ )); do
    KEY=$(echo "$ALIASES" | jq -r "keys[$j]")
    VALUE=$(echo "$ALIASES" | jq -r ".[\"$KEY\"]")
    echo "    Alias \"$KEY\" \"$VALUE\""
    echo "    <Directory \"$VALUE\">"
    echo "        Options Indexes FollowSymLinks"
    echo "        AllowOverride None"
    echo "        Require all granted"
    echo "    </Directory>"
  done
fi)
    ErrorLog ${APACHE_LOG_DIR}/$SERVER_NAME-error.log
    CustomLog ${APACHE_LOG_DIR}/$SERVER_NAME-access.log combined
$(if [[ "$ADD_OPTIONAL_INCLUDE" == "true" ]]; then
    echo "    IncludeOptional custom-enabled/*.conf"
  fi)
</VirtualHost>
EOF
    fi
    
    # HTTPS VHost
    if [[ "$ENABLE_HTTPS" == "true" ]]; then
      bash /opt/scripts/generate_ssl_crt "$SERVER_NAME" "$SSL_DEST_DIR"
      
      cat <<EOF >> "$VHOST_FILE"
<IfModule mod_ssl.c>
  <VirtualHost *:443>
    ServerName $SERVER_NAME
$(if [ ! -z "$SERVER_ALIAS" ]; then
        # 'join' transformiert die JSON-Array-Elemente in eine durch Leerzeichen getrennte Zeichenkette
        ALIAS_STR=$(echo "$SERVER_ALIAS" | jq -r 'join(" ")')
        echo "    ServerAlias $ALIAS_STR"
    fi)
    DocumentRoot $DOCUMENT_ROOT
    SSLEngine on
    SSLCertificateFile      /etc/ssl/certs/${SERVER_NAME}.crt
    SSLCertificateKeyFile   /etc/ssl/private/${SERVER_NAME}.key
$(if [[ $ENV_VARS_COUNT -gt 0 ]]; then
for (( j=0; j<$ENV_VARS_COUNT; j++ )); do
    KEY=$(echo "$ENV_VARS" | jq -r "keys[$j]")
    VALUE=$(echo "$ENV_VARS" | jq -r ".[\"$KEY\"]")
    echo "    SetEnv $KEY \"$VALUE\""
  done
fi)
    AllowEncodedSlashes On
    # we deactivate sendfile for faster static content delivery, because it (pagecache) can make problems with nfs, smb, ... shares
    EnableSendfile Off
    # disabling HSTS will allow your site to be publicly viewed over HTTP and/or insecure HTTPS connection
    Header unset Strict-Transport-Security
    Header always set Strict-Transport-Security "max-age=0;includeSubDomains"
    # activate HTTP/2 protocol
    Protocols h2 h2c http/1.1
    <Directory $DOCUMENT_ROOT>
        Options Indexes FollowSymLinks
        DirectoryIndex index.php index.html
        AllowOverride All
        Require all granted
    </Directory>
    <filesMatch ".(js|css|)$">
        Header set Cache-Control "no-cache" 
    </filesMatch>
$(if [[ $ALIASES_COUNT -gt 0 ]]; then
for (( j=0; j<$ALIASES_COUNT; j++ )); do
    KEY=$(echo "$ALIASES" | jq -r "keys[$j]")
    VALUE=$(echo "$ALIASES" | jq -r ".[\"$KEY\"]")
    echo "    Alias \"$KEY\" \"$VALUE\""
    echo "    <Directory \"$VALUE\">"
    echo "        Options Indexes FollowSymLinks"
    echo "        AllowOverride None"
    echo "        Require all granted"
    echo "    </Directory>"
  done
fi)
    ErrorLog ${APACHE_LOG_DIR}/$SERVER_NAME-error.log
    CustomLog ${APACHE_LOG_DIR}/$SERVER_NAME-access.log combined
$(if [[ "$ADD_OPTIONAL_INCLUDE" == "true" ]]; then
    echo "    IncludeOptional custom-enabled/*.conf"
  fi)
  </VirtualHost>
</IfModule>
EOF
    fi
    
    a2ensite "$SERVER_NAME"
    
    echo "VHost $SERVER_NAME configured."
  else
    echo "VHost $SERVER_NAME already exists. Skipping."
  fi
done

apache2ctl configtest && systemctl reload apache2
